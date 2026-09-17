import Foundation
import Combine

/// Admin credentials
struct AdminCredentials {
    static let username = "ADMIN"
    static let password = "Cleon0208@"
}

/// Admin authentication session
struct AdminSession: Codable {
    let authenticatedAt: Date
    let username: String
    
    var isValid: Bool {
        // Session valid for 24 hours
        let expirationInterval: TimeInterval = 86400
        return Date().timeIntervalSince(authenticatedAt) < expirationInterval
    }
}

/// Tab visibility settings controlled by admin
struct TabVisibilitySettings: Codable, Equatable {
    var patchesEnabled: Bool
    var filesEnabled: Bool
    var freeFireEnabled: Bool
    var freeFireMaxEnabled: Bool
    var bundleExplorerEnabled: Bool
    
    init(
        patchesEnabled: Bool = false,
        filesEnabled: Bool = false,
        freeFireEnabled: Bool = true,
        freeFireMaxEnabled: Bool = true,
        bundleExplorerEnabled: Bool = false
    ) {
        self.patchesEnabled = patchesEnabled
        self.filesEnabled = filesEnabled
        self.freeFireEnabled = freeFireEnabled
        self.freeFireMaxEnabled = freeFireMaxEnabled
        self.bundleExplorerEnabled = bundleExplorerEnabled
    }
    
    enum CodingKeys: String, CodingKey {
        case patchesEnabled, filesEnabled, freeFireEnabled, freeFireMaxEnabled, bundleExplorerEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patchesEnabled = try container.decodeIfPresent(Bool.self, forKey: .patchesEnabled) ?? false
        filesEnabled = try container.decodeIfPresent(Bool.self, forKey: .filesEnabled) ?? false
        freeFireEnabled = try container.decodeIfPresent(Bool.self, forKey: .freeFireEnabled) ?? true
        freeFireMaxEnabled = try container.decodeIfPresent(Bool.self, forKey: .freeFireMaxEnabled) ?? true
        bundleExplorerEnabled = try container.decodeIfPresent(Bool.self, forKey: .bundleExplorerEnabled) ?? false
    }
    
    static let `default` = TabVisibilitySettings(
        patchesEnabled: false,
        filesEnabled: false,
        freeFireEnabled: true,
        freeFireMaxEnabled: true,
        bundleExplorerEnabled: false
    )
}

/// Admin settings manager
class AdminSettings: ObservableObject {
    static let shared = AdminSettings()
    
    @Published var isAdminAuthenticated: Bool = false
    @Published var tabSettings: TabVisibilitySettings
    @Published var demoModeEnabled: Bool = true // 🔥 DEMO MODE: muestra tabs FF/FFMax sin key
    
    private let sessionKey = "com.x.adminSession"
    private let settingsKey = "com.x.tabSettings"
    private let demoModeKey = "com.x.demoModeEnabled"
    
    private init() {
        // Load tab settings
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(TabVisibilitySettings.self, from: data) {
            self.tabSettings = decoded
        } else {
            self.tabSettings = .default
        }
        
        // Load demo mode (default: true)
        self.demoModeEnabled = UserDefaults.standard.object(forKey: demoModeKey) as? Bool ?? true
        
        // Load admin session
        loadAdminSession()
    }
    
    /// Authenticate admin
    func authenticate(username: String, password: String) -> Bool {
        guard username == AdminCredentials.username,
              password == AdminCredentials.password else {
            return false
        }
        
        let session = AdminSession(authenticatedAt: Date(), username: username)
        saveAdminSession(session)
        isAdminAuthenticated = true
        
        return true
    }
    
    /// Logout admin
    func logout() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        isAdminAuthenticated = false
    }
    
    /// Update tab visibility
    func updateTabSettings(_ settings: TabVisibilitySettings) {
        self.tabSettings = settings
        saveTabSettings()
    }
    
    /// Toggle individual tabs
    func togglePatches() {
        tabSettings.patchesEnabled.toggle()
        saveTabSettings()
    }
    
    func toggleFiles() {
        tabSettings.filesEnabled.toggle()
        saveTabSettings()
    }
    
    func toggleFreeFire() {
        tabSettings.freeFireEnabled.toggle()
        saveTabSettings()
    }
    
    func toggleFreeFireMax() {
        tabSettings.freeFireMaxEnabled.toggle()
        saveTabSettings()
    }
    
    func toggleBundleExplorer() {
        tabSettings.bundleExplorerEnabled.toggle()
        saveTabSettings()
    }
    
    /// Toggle demo mode (shows FF/FFMax tabs without key requirement)
    func toggleDemoMode() {
        demoModeEnabled.toggle()
        UserDefaults.standard.set(demoModeEnabled, forKey: demoModeKey)
    }
    
    // MARK: - Persistence
    
    private func saveAdminSession(_ session: AdminSession) {
        if let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: sessionKey)
        }
    }
    
    private func loadAdminSession() {
        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let session = try? JSONDecoder().decode(AdminSession.self, from: data),
           session.isValid {
            isAdminAuthenticated = true
        } else {
            isAdminAuthenticated = false
            UserDefaults.standard.removeObject(forKey: sessionKey)
        }
    }
    
    func saveTabSettings() {
        if let encoded = try? JSONEncoder().encode(tabSettings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
}
