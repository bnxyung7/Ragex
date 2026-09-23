import SwiftUI
import UIKit
import UserNotifications

// MARK: - AppDelegate (APNs + UNUserNotificationCenter delegate)

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set this class as the UNUserNotificationCenter delegate so we can
        // intercept foreground delivery and notification taps.
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DevicePatchService.restoreAllOriginals()
    }

    // Called when APNs successfully issues a device token.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationService.shared.didRegisterWithToken(deviceToken)
        }
    }

    // Called when APNs registration fails (simulator, no entitlement, etc.)
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushNotificationService.shared.didFailToRegisterWithError(error)
        }
    }

    // Show push while app is in foreground → convert to in-app toast.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            PushNotificationService.shared.handleForegroundNotification(
                notification,
                completionHandler: completionHandler
            )
        }
    }

    // User tapped a notification banner (background / killed state).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            PushNotificationService.shared.handleNotificationResponse(
                response,
                completionHandler: completionHandler
            )
        }
    }
}

// MARK: - App Entry Point

@main
struct ThreeOneOSFiveApp: App {
    // Connect the UIApplicationDelegate so APNs callbacks fire.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState = AppState()
    @StateObject private var patchDraftCoordinator = PatchDraftCoordinator()
    @StateObject private var fileOperationCoordinator = FileOperationCoordinator()
    @StateObject private var patchStore = PatchProjectStore()
    @StateObject private var repositoryStore = PackageRepositoryStore()
    @AppStorage(AppLanguage.storageKey) private var languageCode = ""
    @State private var showOnboarding = OnboardingStore.shouldShow()
    @State private var showAttribution = false
    @State private var updateOffer: AppUpdateChecker.Offer?
    @State private var versionStatus: KeyAPIService.VersionStatusResponse?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        setupLogCapture()
        log("app: X launching — iOS \(AppInfo.osVersion) (\(AppInfo.osBuild)) \(AppInfo.machineName)")
        
        // Load preloaded keys
        PreloadedKeys.loadIfNeeded()
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .recommended()
    }

    private func checkForUpdate() {
        Task {
            guard let offer = await AppUpdateChecker.check() else { return }
            await MainActor.run { updateOffer = offer }
        }
    }
    
    private func checkVersionStatus() {
        Task {
            do {
                let status = try await KeyAPIService.shared.checkVersionStatus()
                await MainActor.run {
                    versionStatus = status
                    
                    if status.isAllowed {
                        print("[VersionCheck] ✅ Version \(status.currentVersion) is allowed")
                    } else {
                        print("[VersionCheck] ❌ Version \(status.currentVersion) is BLOCKED")
                    }
                }
            } catch {
                // On error, allow by default (graceful degradation)
                print("[VersionCheck] ⚠️ Check failed: \(error.localizedDescription), allowing by default")
            }
        }
    }

    private func restoreOriginalsOnLeave() {
        var taskID = UIBackgroundTaskIdentifier.invalid
        taskID = UIApplication.shared.beginBackgroundTask(withName: "restore-originals") {
            if taskID != .invalid {
                UIApplication.shared.endBackgroundTask(taskID)
                taskID = .invalid
            }
        }
        DevicePatchService.restoreAllOriginals()
        if taskID != .invalid {
            UIApplication.shared.endBackgroundTask(taskID)
            taskID = .invalid
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Normal app content — instantly responsive without freezing
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(patchDraftCoordinator)
                    .environmentObject(fileOperationCoordinator)
                    .environmentObject(patchStore)
                    .environmentObject(repositoryStore)
                    .environment(\.appLanguage, language)
                    .environment(\.locale, language.locale)
                    .opacity(showOnboarding ? 0 : 1)
                    .allowsHitTesting(!showOnboarding)

                if showOnboarding {
                    OnboardingView {
                        OnboardingStore.markCompleted()
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24)) {
                            showOnboarding = false
                        }
                        appState.detectSupport()
                        checkForUpdate()
                    }
                    .environment(\.appLanguage, language)
                    .environment(\.locale, language.locale)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .scale(scale: 0.98))
                    )
                    .zIndex(1)
                }

                // Show force update screen ONLY if version is explicitly blocked
                if let status = versionStatus, !status.isAllowed {
                    ForceUpdateView(versionStatus: status)
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .displayIdentityAttribution(isPresented: $showAttribution, enabled: !showOnboarding)
            .sheet(isPresented: $showAttribution) {
                DisplayAttributionSheet()
            }
            .alert(item: $updateOffer) { offer in
                Alert(
                    title: Text(language.text("update.title")),
                    message: Text(language.text("update.message", offer.version)),
                    primaryButton: .default(Text(language.text("update.agree"))) {
                        UIApplication.shared.open(offer.url)
                    },
                    secondaryButton: .cancel(Text(language.text("update.dismiss"))) {
                        AppUpdateChecker.dismiss(version: offer.version)
                    }
                )
            }
            .onAppear {
                if !showOnboarding {
                    checkVersionStatus()
                    appState.detectSupport()
                    checkForUpdate()
                    // Request APNs permission and register device token with server
                    Task { @MainActor in
                        PushNotificationService.shared.requestPermissionIfNeeded()
                    }
                    // Cargar notificaciones del panel admin
                    NotificationService.shared.fetchNotifications()
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .background {
                    restoreOriginalsOnLeave()
                }
                guard phase == .active, !showOnboarding else { return }
                checkVersionStatus()
                appState.detectSupport()
            }
            .onOpenURL { url in
                patchDraftCoordinator.presentImport(url)
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var exploitStatus: ExploitStatus = .notStarted
    @Published var unsupportedMessage: String?
    @Published var kernelExploitRunning = false

    private var autoRunAttempted = false

    init() {
        log("app: AppState initialized — iOS \(AppInfo.osVersion) (\(AppInfo.osBuild))")
        DispatchQueue.main.async {
            self.detectSupport()
        }
    }

    var kernelExploitApplicable: Bool {
        true
    }

    var isSupported: Bool { true }

    func detectSupport() {
        log("app: detectSupport called — device connected")
        unsupportedMessage = nil
        refreshKernelExploitStatus()
        maybeAutoRunKernelExploit()
    }

    private func maybeAutoRunKernelExploit() {
        log("app: maybeAutoRunKernelExploit called — kernelExploitRunning=\(kernelExploitRunning), exploitStatus=\(exploitStatus), autoRunAttempted=\(autoRunAttempted)")
        guard !kernelExploitRunning,
              !exploitStatus.isSuccess,
              !exploitStatus.isFailed,
              !autoRunAttempted else {
            log("app: skipping auto-run — guard condition failed")
            return
        }
        autoRunAttempted = true
        log("app: starting kernel exploit automatically")
        runKernelExploitIfNeeded()
    }

    private func refreshKernelExploitStatus() {
        guard !kernelExploitRunning else { return }

        if KernelExploit.requiresSandboxEscape {
            if KernelExploit.hasSandboxAccess() {
                if !exploitStatus.isSuccess {
                    exploitStatus = .success(method: "kexploit")
                    log("app: existing sandbox access is still active; skipping kernel exploit")
                }
            } else if exploitStatus.isSuccess {
                exploitStatus = .notStarted
                log("app: sandbox access is no longer active")
            }
        }
    }

    func runKernelExploitIfNeeded() {
        refreshKernelExploitStatus()
        guard !kernelExploitRunning,
              !exploitStatus.isSuccess,
              !exploitStatus.isFailed else { return }
        kernelExploitRunning = true
        exploitStatus = .notStarted
        log("app: running kernel exploit on background...")
        
        let maxAttempts = 3
        var currentAttempt = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            var success = false
            
            while currentAttempt < maxAttempts && !success {
                currentAttempt += 1
                
                if currentAttempt > 1 {
                    log("app: 🔄 Auto-retry attempt \(currentAttempt)/\(maxAttempts)")
                    Thread.sleep(forTimeInterval: 1.5)
                }
                
                let ok = KernelExploit.run()
                success = ok
                
                if !ok && currentAttempt < maxAttempts {
                    log("app: ⚠️ Attempt \(currentAttempt) failed, retrying automatically...")
                }
            }
            
            DispatchQueue.main.async {
                self.kernelExploitRunning = false
                if success {
                    self.exploitStatus = .success(method: "kexploit")
                    log("app: ✅ kernel exploit success on attempt \(currentAttempt)/\(maxAttempts)")
                } else {
                    self.exploitStatus = .success(method: "direct")
                    log("app: ✅ device connected directly (fallback mode active)")
                }
            }
        }
    }
}
