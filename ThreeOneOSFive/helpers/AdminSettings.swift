import Foundation
import Combine

/// Admin credentials
struct AdminCredentials {
    static let username = "ADMIN"
    static let password = "JOSTIN2324"
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
    var bundleExplorerEnabled: Bool
    
    static let `default` = TabVisibilitySettings(
        patchesEnabled: false,         // Hidden by default
        filesEnabled: false,            // Hidden by default
        freeFireEnabled: true,          // Always visible
        bundleExplorerEnabled: true     // Visible by default (public access)
    )
}

/// Admin settings manager
class AdminSettings: ObservableObject {
    static let shared = AdminSettings()
    
    @Published var isAdminAuthenticated: Bool = false
    @Published var tabSettings: TabVisibilitySettings
    
    private let sessionKey = "com.x.adminSession"
    private let settingsKey = "com.x.tabSettings"
    
    private init() {
        // Load tab settings
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(TabVisibilitySettings.self, from: data) {
            self.tabSettings = decoded
        } else {
            self.tabSettings = .default
        }
        
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
    
    func toggleBundleExplorer() {
        tabSettings.bundleExplorerEnabled.toggle()
        saveTabSettings()
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
