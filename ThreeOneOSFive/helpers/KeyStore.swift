import Foundation
import Combine

/// Service for managing user keys
class KeyStore: ObservableObject {
    static let shared = KeyStore()
    
    @Published var allKeys: [UserKey] = []
    @Published var activeSession: UserSession?
    
    private let keysKey = "com.x.allKeys"
    private let sessionKey = "com.x.activeSession"
    
    private init() {
        loadKeys()
        loadSession()
        startExpirationTimer()
    }
    
    /// Generate a new key with format JUSTINRAGEX-XXX-XXX
    func generateKey() -> String {
        let prefix = "JUSTINRAGEX"
        let part1 = String(format: "%03d", Int.random(in: 0...999))
        let part2 = String(format: "%03d", Int.random(in: 0...999))
        return "\(prefix)-\(part1)-\(part2)"
    }
    
    /// Create a new key
    func createKey(duration: KeyDuration, userName: String? = nil) -> UserKey {
        let keyString = generateKey()
        let key = UserKey(keyString: keyString, duration: duration, userName: userName)
        
        allKeys.append(key)
        saveKeys()
        
        return key
    }
    
    /// Validate key format
    func isValidFormat(_ keyString: String) -> Bool {
        let pattern = "^JUSTINRAGEX-\\d{3}-\\d{3}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(keyString.startIndex..., in: keyString)
        return regex?.firstMatch(in: keyString, options: [], range: range) != nil
    }
    
    /// Activate a key for the user
    func activateKey(_ keyString: String) -> Result<UserSession, KeyActivationError> {
        // Validate format
        guard isValidFormat(keyString) else {
            return .failure(.invalidFormat)
        }
        
        // Find key
        guard let key = allKeys.first(where: { $0.keyString == keyString }) else {
            return .failure(.notFound)
        }
        
        // Check expiration
        guard !key.isExpired else {
            return .failure(.expired)
        }
        
        // Create session
        let session = UserSession(key: key, activatedAt: Date())
        activeSession = session
        saveSession()
        
        return .success(session)
    }
    
    /// Deactivate current session
    func deactivateSession() {
        activeSession = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }
    
    /// Check if user has valid access
    func hasValidAccess() -> Bool {
        guard let session = activeSession else {
            return false
        }
        return session.isValid
    }
    
    /// Revoke/delete a key
    func revokeKey(_ key: UserKey) {
        allKeys.removeAll { $0.id == key.id }
        
        // If it's the active session, deactivate
        if activeSession?.key.id == key.id {
            deactivateSession()
        }
        
        saveKeys()
    }
    
    /// Get all active keys
    var activeKeys: [UserKey] {
        return allKeys.filter { !$0.isExpired }
    }
    
    /// Get all expired keys
    var expiredKeys: [UserKey] {
        return allKeys.filter { $0.isExpired }
    }
    
    // MARK: - Persistence
    
    private func saveKeys() {
        if let encoded = try? JSONEncoder().encode(allKeys) {
            UserDefaults.standard.set(encoded, forKey: keysKey)
        }
    }
    
    private func loadKeys() {
        if let data = UserDefaults.standard.data(forKey: keysKey),
           let decoded = try? JSONDecoder().decode([UserKey].self, from: data) {
            allKeys = decoded
        }
    }
    
    private func saveSession() {
        if let session = activeSession,
           let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: sessionKey)
        }
    }
    
    private func loadSession() {
        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let decoded = try? JSONDecoder().decode(UserSession.self, from: data) {
            // Only load if still valid
            if !decoded.key.isExpired {
                activeSession = decoded
            } else {
                UserDefaults.standard.removeObject(forKey: sessionKey)
            }
        }
    }
    
    // MARK: - Expiration Timer
    
    private var expirationTimer: Timer?
    
    private func startExpirationTimer() {
        // Check every minute for expired sessions
        expirationTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkExpiration()
        }
    }
    
    private func checkExpiration() {
        if let session = activeSession, session.key.isExpired {
            deactivateSession()
            print("[KeyStore] Session expired, deactivated")
        }
    }
}

/// Key activation errors
enum KeyActivationError: LocalizedError {
    case invalidFormat
    case notFound
    case expired
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Formato de Key inválido. Use: JUSTINRAGEX-XXX-XXX"
        case .notFound:
            return "Key no encontrada. Verifica tu Key."
        case .expired:
            return "Esta Key ha expirado."
        }
    }
}
