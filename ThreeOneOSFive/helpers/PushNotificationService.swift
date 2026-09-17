import Foundation
import UIKit
import UserNotifications
import Combine

// MARK: - PushNotificationService
//
// Responsibilities:
//  1. Request OS notification permission on first launch.
//  2. Capture APNs device token and upload to admin API, keyed by
//     active keyString so the web panel can target specific users
//     or broadcast to all.
//  3. Offline-safe: if the upload fails, the pending token+key is
//     persisted in UserDefaults and retried on next foreground.
//  4. Handle foreground delivery → in-app toast.
//  5. Handle background tap → open deep-link.

@MainActor
public final class PushNotificationService: NSObject, ObservableObject {

    // MARK: - Singleton
    public static let shared = PushNotificationService()

    // MARK: - Published state (usable in UI)
    @Published public private(set) var permissionGranted: Bool = false
    @Published public private(set) var permissionDetermined: Bool = false
    @Published public private(set) var deviceTokenString: String? = nil

    // MARK: - Private
    private let tokenKey        = "com.x.apnsDeviceToken"
    private let pendingKey      = "com.x.apnsPendingUpload"   // { token, keyString } stored when offline
    private var uploadedSignature: String? = nil               // "token:keyString" → skip re-upload
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        deviceTokenString = UserDefaults.standard.string(forKey: tokenKey)
        checkCurrentPermission()
        observeSessionChanges()
        observeForeground()
    }

    // MARK: - Permission

    /// Safe to call multiple times. Asks for permission if not yet determined.
    public func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionDetermined = settings.authorizationStatus != .notDetermined
                switch settings.authorizationStatus {
                case .notDetermined:
                    self?.requestPermission()
                case .authorized, .provisional, .ephemeral:
                    self?.permissionGranted = true
                    self?.permissionDetermined = true
                    UIApplication.shared.registerForRemoteNotifications()
                default:
                    self?.permissionGranted = false
                    self?.permissionDetermined = true
                }
            }
        }
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                self?.permissionDetermined = true
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    private func checkCurrentPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionDetermined = settings.authorizationStatus != .notDetermined
                self?.permissionGranted = (settings.authorizationStatus == .authorized ||
                                           settings.authorizationStatus == .provisional)
            }
        }
    }

    // MARK: - Token Handling (called from AppDelegate)

    public func didRegisterWithToken(_ tokenData: Data) {
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceTokenString = tokenString
        UserDefaults.standard.set(tokenString, forKey: tokenKey)
        print("[Push] 📲 APNs token received")
        uploadTokenToServer(token: tokenString)
    }

    public func didFailToRegisterWithError(_ error: Error) {
        print("[Push] ❌ APNs registration failed: \(error.localizedDescription)")
    }

    // MARK: - Server Registration with offline retry

    /// Uploads token to the API. Persists as "pending" if network fails so
    /// the next foreground call retries automatically.
    private func uploadTokenToServer(token: String) {
        let keyString = KeyStore.shared.activeSession?.key.keyString ?? "anonymous"
        let signature = "\(token):\(keyString)"

        guard uploadedSignature != signature else { return }    // already uploaded

        Task {
            do {
                try await KeyAPIService.shared.registerDevicePushToken(
                    token: token,
                    keyString: keyString
                )
                await MainActor.run {
                    self.uploadedSignature = signature
                    self.clearPendingUpload()
                    print("[Push] ✅ Token registered for key: \(keyString)")
                }
            } catch {
                await MainActor.run {
                    self.savePendingUpload(token: token, keyString: keyString)
                    print("[Push] ⚠️ Token upload failed — queued for retry: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Retries any pending upload that failed while offline.
    public func retryPendingUploadIfNeeded() {
        guard let pending = loadPendingUpload() else { return }
        print("[Push] 🔄 Retrying pending token upload…")
        uploadedSignature = nil   // reset so it re-tries
        uploadTokenToServer(token: pending.token)
    }

    // MARK: - Pending upload persistence

    private struct PendingUpload: Codable {
        let token: String
        let keyString: String
    }

    private func savePendingUpload(token: String, keyString: String) {
        let pending = PendingUpload(token: token, keyString: keyString)
        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
    }

    private func loadPendingUpload() -> PendingUpload? {
        guard let data = UserDefaults.standard.data(forKey: pendingKey),
              let pending = try? JSONDecoder().decode(PendingUpload.self, from: data)
        else { return nil }
        return pending
    }

    private func clearPendingUpload() {
        UserDefaults.standard.removeObject(forKey: pendingKey)
    }

    // MARK: - Observers

    /// Re-register when user activates a new key session.
    private func observeSessionChanges() {
        KeyStore.shared.$activeSession
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.uploadedSignature = nil   // force re-upload for new key
                guard let token = self?.deviceTokenString else { return }
                self?.uploadTokenToServer(token: token)
            }
            .store(in: &cancellables)
    }

    /// On every foreground: retry failed uploads + re-check permission status.
    private func observeForeground() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkCurrentPermission()
            self?.retryPendingUploadIfNeeded()
        }
    }

    // MARK: - Foreground push delivery

    /// Called from UNUserNotificationCenterDelegate.willPresent(_:withCompletionHandler:)
    public func handleForegroundNotification(
        _ notification: UNNotification,
        completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let content  = notification.request.content
        let userInfo = content.userInfo

        let linkURL   = userInfo["linkURL"]   as? String
        let linkTitle = userInfo["linkTitle"] as? String
        let isUrgent  = (userInfo["urgent"]   as? Bool) ?? false

        // Show via in-app toast queue
        NotificationService.shared.enqueueToast(
            title:     content.title,
            message:   content.body,
            type:      isUrgent ? .warning : .admin,
            linkURL:   linkURL,
            linkTitle: linkTitle,
            isUrgent:  isUrgent
        )

        // Also insert into broadcast message list
        let broadcast = AdminBroadcastMessage(
            id:        notification.request.identifier,
            title:     content.title,
            message:   content.body,
            timestamp: "Ahora",
            linkURL:   linkURL,
            linkTitle: linkTitle,
            isUrgent:  isUrgent
        )
        NotificationService.shared.insertBroadcast(broadcast, showToast: false)

        // We handled it ourselves — suppress system banner
        completionHandler([])
    }

    /// Called from UNUserNotificationCenterDelegate.didReceive(_:withCompletionHandler:)
    public func handleNotificationResponse(
        _ response: UNNotificationResponse,
        completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let linkURL  = userInfo["linkURL"] as? String

        if let urlString = linkURL, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }

        completionHandler()
    }
}
