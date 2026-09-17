import Foundation
import Combine
import SwiftUI
import UIKit
import UserNotifications

// MARK: - InAppToastItem

public struct InAppToastItem: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let type: ToastType
    public let linkURL: String?
    public let linkTitle: String?
    public let createdAt = Date()
    /// Urgent toasts stay visible longer (10s vs 6s)
    public let isUrgent: Bool

    public init(
        title: String,
        message: String,
        type: ToastType,
        linkURL: String? = nil,
        linkTitle: String? = nil,
        isUrgent: Bool = false
    ) {
        self.title = title
        self.message = message
        self.type = type
        self.linkURL = linkURL
        self.linkTitle = linkTitle
        self.isUrgent = isUrgent
    }

    public enum ToastType {
        case admin
        case warning
        case info
        case success

        var icon: String {
            switch self {
            case .admin:   return "megaphone.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info:    return "bell.fill"
            case .success: return "checkmark.seal.fill"
            }
        }

        var badgeText: String {
            switch self {
            case .admin:   return "ADMINISTRACIÓN"
            case .warning: return "AVISO"
            case .info:    return "NOTICIA"
            case .success: return "SISTEMA"
            }
        }

        var color: Color {
            switch self {
            case .admin:   return AppTheme.accent
            case .warning: return Color(hex: "F59E0B")
            case .info:    return Color(hex: "3B82F6")
            case .success: return Color(hex: "10B981")
            }
        }
    }
}

// MARK: - AdminBroadcastMessage

public struct AdminBroadcastMessage: Identifiable, Codable, Equatable {
    public let id: String
    public let title: String
    public let message: String
    public let timestamp: String
    public let linkURL: String?
    public let linkTitle: String?
    public let isUrgent: Bool?

    public init(
        id: String = UUID().uuidString,
        title: String,
        message: String,
        timestamp: String = "Ahora",
        linkURL: String? = nil,
        linkTitle: String? = nil,
        isUrgent: Bool? = false
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.linkURL = linkURL
        self.linkTitle = linkTitle
        self.isUrgent = isUrgent
    }
}

// MARK: - NotificationService

@MainActor
public class NotificationService: ObservableObject {
    public static let shared = NotificationService()

    // MARK: Published
    @Published public var activeToast: InAppToastItem? = nil
    /// Queue of toasts waiting to display after the current one is dismissed
    @Published public var toastQueue: [InAppToastItem] = []
    @Published public var broadcastMessages: [AdminBroadcastMessage] = []
    @Published public var readMessageIDs: Set<String> = []
    @Published public var showNotificationsSheet: Bool = false

    // MARK: Private
    private var dismissTimer: AnyCancellable?
    private var syncTimer: AnyCancellable?
    private var lastNotifiedExpirationState: Bool = false
    private var lastNotifiedWarningDate: Date? = nil

    private let readIDsKey       = "com.x.readBroadcastMessages"
    private let broadcastStoreKey = "com.x.broadcastMessages.v2"

    // MARK: Init
    private init() {
        loadReadIDs()
        loadPersistedBroadcasts()   // restore messages from last session
        mergeDefaultMessages()
        startSyncTimer()
        observeForeground()
    }

    // MARK: - Unread count

    public var unreadCount: Int {
        broadcastMessages.filter { !readMessageIDs.contains($0.id) }.count
    }

    // MARK: - Timers / observers

    public func startSyncTimer() {
        syncTimer?.cancel()
        syncTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.fetchAdminBroadcasts() }
            }
    }

    private func observeForeground() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchAdminBroadcasts()
            }
        }
    }

    // MARK: - Remote broadcast fetch

    public func fetchAdminBroadcasts() async {
        do {
            guard let url = URL(string: "https://xkeyapi.onrender.com/api/notifications") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("xkey_admin_secret_token_2026", forHTTPHeaderField: "X-API-Token")
            request.timeoutInterval = 8

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }

            struct BroadcastResponse: Codable {
                let success: Bool?
                let notifications: [AdminBroadcastMessage]?
                let messages: [AdminBroadcastMessage]?
                let data: [AdminBroadcastMessage]?
            }

            let decoded = try JSONDecoder().decode(BroadcastResponse.self, from: data)
            let items = decoded.notifications ?? decoded.messages ?? decoded.data ?? []

            for item in items {
                insertBroadcast(item, showToast: true)
            }
        } catch {
            // Keep existing messages — silently fail
        }
    }

    /// Insert a broadcast, deduplicating by id. Shows toast if `showToast` and message is new.
    public func insertBroadcast(_ msg: AdminBroadcastMessage, showToast: Bool) {
        guard !broadcastMessages.contains(where: { $0.id == msg.id }) else { return }
        broadcastMessages.insert(msg, at: 0)
        persistBroadcasts()

        if showToast {
            enqueueToast(
                title: msg.title,
                message: msg.message,
                type: msg.isUrgent == true ? .warning : .admin,
                linkURL: msg.linkURL,
                linkTitle: msg.linkTitle,
                isUrgent: msg.isUrgent == true
            )
        }
    }

    // MARK: - Toast system (queue-based)

    /// Add a toast to the queue. Displays immediately if nothing is active.
    public func enqueueToast(
        title: String,
        message: String,
        type: InAppToastItem.ToastType = .info,
        linkURL: String? = nil,
        linkTitle: String? = nil,
        isUrgent: Bool = false
    ) {
        let toast = InAppToastItem(
            title: title,
            message: message,
            type: type,
            linkURL: linkURL,
            linkTitle: linkTitle,
            isUrgent: isUrgent
        )

        if activeToast == nil {
            displayToast(toast)
        } else {
            toastQueue.append(toast)
        }
    }

    /// Legacy name kept for compatibility
    public func showToast(
        title: String,
        message: String,
        type: InAppToastItem.ToastType = .info,
        linkURL: String? = nil,
        linkTitle: String? = nil
    ) {
        enqueueToast(title: title, message: message, type: type, linkURL: linkURL, linkTitle: linkTitle)
    }

    private func displayToast(_ toast: InAppToastItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            activeToast = toast
        }

        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(toast.type == .warning ? .warning : .success)

        let duration: Double = toast.isUrgent ? 10 : 6
        dismissTimer?.cancel()
        dismissTimer = Just(())
            .delay(for: .seconds(duration), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if self.activeToast?.id == toast.id {
                    self.advanceToastQueue()
                }
            }
    }

    /// Called when the current toast auto-dismisses or is swiped away.
    public func dismissToast() {
        withAnimation(.easeOut(duration: 0.2)) {
            activeToast = nil
        }
        dismissTimer?.cancel()
        // Small delay so the outgoing animation finishes before the next one starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.advanceToastQueueIfNeeded()
        }
    }

    private func advanceToastQueue() {
        withAnimation(.easeOut(duration: 0.2)) {
            activeToast = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.advanceToastQueueIfNeeded()
        }
    }

    private func advanceToastQueueIfNeeded() {
        guard activeToast == nil, !toastQueue.isEmpty else { return }
        let next = toastQueue.removeFirst()
        displayToast(next)
    }

    // MARK: - Expiry notifications

    public func notifyExpiringSoon(minutesLeft: Int) {
        if let last = lastNotifiedWarningDate, Date().timeIntervalSince(last) < 600 { return }
        lastNotifiedWarningDate = Date()

        enqueueToast(
            title: "⚠️ Key por Expirar",
            message: "Tu clave vencerá en \(minutesLeft) minutos. Renueva para no perder acceso a Free Fire.",
            type: .warning,
            linkURL: "https://wa.me/18099289722?text=Hola,%20mi%20clave%20esta%20por%20expirar%20y%20deseo%20renovarla",
            linkTitle: "Renovar Ahora",
            isUrgent: true
        )
        // Also schedule a local OS notification so the user sees it if the app is killed
        scheduleLocalNotification(
            id: "expiry-warning-\(minutesLeft)",
            title: "⚠️ Key por Expirar",
            body: "Tu clave vence en \(minutesLeft) minutos. Abre la app para renovarla.",
            delay: 1
        )
    }

    public func notifyExpired() {
        if lastNotifiedExpirationState { return }
        lastNotifiedExpirationState = true

        enqueueToast(
            title: "⛔ Membresía Expirada",
            message: "Tu clave ha vencido. Las pestañas Free Fire se han ocultado. Toca para renovar.",
            type: .warning,
            linkURL: "https://wa.me/18099289722?text=Hola,%20mi%20clave%20ha%20expirado%20y%20deseo%20renovarla",
            linkTitle: "Renovar Clave",
            isUrgent: true
        )
        scheduleLocalNotification(
            id: "expiry-expired",
            title: "⛔ Membresía Expirada",
            body: "Tu clave Project X ha vencido. Abre la app y renueva tu membresía.",
            delay: 1
        )
    }

    public func resetExpirationNotification() {
        lastNotifiedExpirationState = false
        lastNotifiedWarningDate = nil
    }

    // MARK: - Local OS notifications (works while app is killed)

    private func scheduleLocalNotification(id: String, title: String, body: String, delay: TimeInterval) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("[NotificationService] Local notification error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Read state

    public func markAsRead(id: String) {
        readMessageIDs.insert(id)
        saveReadIDs()
    }

    public func markAllAsRead() {
        broadcastMessages.forEach { readMessageIDs.insert($0.id) }
        saveReadIDs()
    }

    // MARK: - Persistence

    private func persistBroadcasts() {
        // Keep at most 50 messages to limit storage
        let toStore = Array(broadcastMessages.prefix(50))
        if let encoded = try? JSONEncoder().encode(toStore) {
            UserDefaults.standard.set(encoded, forKey: broadcastStoreKey)
        }
    }

    private func loadPersistedBroadcasts() {
        guard let data = UserDefaults.standard.data(forKey: broadcastStoreKey),
              let decoded = try? JSONDecoder().decode([AdminBroadcastMessage].self, from: data)
        else { return }
        broadcastMessages = decoded
    }

    private func mergeDefaultMessages() {
        let defaults: [AdminBroadcastMessage] = [
            AdminBroadcastMessage(
                id: "adm-msg-ff-dual",
                title: "🔥 Nuevo Soporte Free Fire MAX",
                message: "Hemos habilitado la inyección dual para Free Fire Normal y MAX en tiempo real.",
                timestamp: "Hoy",
                linkURL: "https://wa.me/18099289722",
                linkTitle: "Canal Oficial",
                isUrgent: true
            ),
            AdminBroadcastMessage(
                id: "adm-msg-renewal",
                title: "💎 Renovaciones y Soporte 24/7",
                message: "Si tu membresía vence, tu sesión permanece en Perfil para que puedas ingresar tu nueva key directamente.",
                timestamp: "Aviso",
                linkURL: "https://wa.me/18099289722?text=Hola,%20deseo%20renovar%20mi%20membresia%20Project%20X",
                linkTitle: "Contactar WhatsApp",
                isUrgent: false
            )
        ]
        for msg in defaults {
            if !broadcastMessages.contains(where: { $0.id == msg.id }) {
                broadcastMessages.append(msg)
            }
        }
        persistBroadcasts()
    }

    private func loadReadIDs() {
        if let stored = UserDefaults.standard.array(forKey: readIDsKey) as? [String] {
            readMessageIDs = Set(stored)
        }
    }

    private func saveReadIDs() {
        UserDefaults.standard.set(Array(readMessageIDs), forKey: readIDsKey)
    }
}
