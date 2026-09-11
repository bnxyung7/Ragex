import Foundation
import Combine
import UIKit

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
    
    /// Get unique device identifier
    private func getDeviceId() -> String {
        // Use identifierForVendor as device ID
        if let uuid = UIDevice.current.identifierForVendor {
            return uuid.uuidString
        }
        // Fallback: generate and store a UUID
        let key = "com.x.deviceId"
        if let stored = UserDefaults.standard.string(forKey: key) {
            return stored
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    /// Generate a new key with format JUSTINRAGEX-XXX-XXX
    func generateKey() -> String {
        let prefix = "JUSTINRAGEX"
        let part1 = String(format: "%03d", Int.random(in: 0...999))
        let part2 = String(format: "%03d", Int.random(in: 0...999))
        return "\(prefix)-\(part1)-\(part2)"
    }
    
    /// Create a new key (local + remote API)
    func createKey(duration: KeyDuration, userName: String? = nil) -> UserKey {
        let keyString = generateKey()
        let key = UserKey(keyString: keyString, duration: duration, userName: userName)
        
        // Save locally
        allKeys.append(key)
        saveKeys()
        
        // Also send to API for cross-device validation
        Task {
            do {
                try await KeyAPIService.shared.createKeyOnServer(
                    keyString: keyString,
                    duration: duration.rawValue,
                    userName: userName
                )
                print("[KeyStore] Key created on server: \(keyString)")
            } catch {
                print("[KeyStore] Failed to create key on server: \(error.localizedDescription)")
                // Key is still valid locally even if API fails
            }
        }
        
        return key
    }
    
    /// Validate key format
    func isValidFormat(_ keyString: String) -> Bool {
        let pattern = "^JUSTINRAGEX-\\d{3}-\\d{3}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(keyString.startIndex..., in: keyString)
        return regex?.firstMatch(in: keyString, options: [], range: range) != nil
    }
    
    /// Activate a key for the user (with API validation and device binding)
    func activateKey(_ keyString: String, completion: @escaping (Result<UserSession, KeyActivationError>) -> Void) {
        // Validate format
        guard isValidFormat(keyString) else {
            completion(.failure(.invalidFormat))
            return
        }
        
        let deviceId = getDeviceId()
        
        // Try remote validation with device ID
        Task {
            do {
                // First validate
                let validationResult = try await KeyAPIService.shared.validateKeyWithDevice(keyString, deviceId: deviceId)
                
                await MainActor.run {
                    if validationResult.valid {
                        if validationResult.needsActivation == true {
                            // Key needs activation - activate it now
                            Task {
                                do {
                                    try await KeyAPIService.shared.activateKey(keyString, deviceId: deviceId)
                                    
                                    // Create local session after activation
                                    await MainActor.run {
                                        self.createSession(keyString: keyString, completion: completion)
                                    }
                                } catch {
                                    await MainActor.run {
                                        print("[KeyStore] Activation failed: \(error.localizedDescription)")
                                        completion(.failure(.notFound))
                                    }
                                }
                            }
                        } else {
                            // Key already activated on this device
                            self.createSession(keyString: keyString, completion: completion)
                        }
                    } else {
                        // Determine error type
                        if let reason = validationResult.reason {
                            if reason.contains("expired") {
                                completion(.failure(.expired))
                            } else if reason.contains("another device") || reason.contains("activated") {
                                completion(.failure(.alreadyActivated))
                            } else {
                                completion(.failure(.notFound))
                            }
                        } else {
                            completion(.failure(.notFound))
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    print("[KeyStore] Validation error: \(error.localizedDescription)")
                    completion(.failure(.notFound))
                }
            }
        }
    }
    
    private func createSession(keyString: String, completion: @escaping (Result<UserSession, KeyActivationError>) -> Void) {
        // Find or create local key
        var key: UserKey
        
        if let existingKey = self.allKeys.first(where: { $0.keyString == keyString }) {
            key = existingKey
        } else {
            // Create local copy
            print("[KeyStore] Creating local copy of key")
            key = UserKey(keyString: keyString, duration: .sevenDays, userName: nil)
            self.allKeys.append(key)
            self.saveKeys()
        }
        
        // Create session
        let session = UserSession(key: key, activatedAt: Date())
        self.activeSession = session
        self.saveSession()
        
        completion(.success(session))
    }
    
    /// Activate key synchronously (legacy, for local-only validation)
    func activateKeyLocal(_ keyString: String) -> Result<UserSession, KeyActivationError> {
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
        
        // Check banned
        guard !key.isBanned else {
            return .failure(.notFound) // Treat as not found
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
        return session.isValid && !session.key.isBanned
    }
    
    // MARK: - Key Management Operations
    
    /// Reset key expiration to original duration
    func resetKey(_ key: UserKey) {
        guard let index = allKeys.firstIndex(where: { $0.id == key.id }) else { return }
        
        var updatedKey = key
        
        // Reset expiration based on original duration
        if let interval = key.duration.timeInterval {
            updatedKey.expiresAt = Date().addingTimeInterval(interval)
        }
        
        // Add notification
        updatedKey.notifications.append(.reset)
        
        allKeys[index] = updatedKey
        
        // Update active session if this is the active key
        if activeSession?.key.id == key.id {
            activeSession = UserSession(key: updatedKey, activatedAt: activeSession!.activatedAt)
        }
        
        saveKeys()
        saveSession()
    }
    
    /// Add days to key
    func addTime(to key: UserKey, days: Int) {
        guard let index = allKeys.firstIndex(where: { $0.id == key.id }) else { return }
        guard days > 0 else { return }
        
        var updatedKey = key
        
        // Add time
        if let currentExpiration = updatedKey.expiresAt {
            updatedKey.expiresAt = currentExpiration.addingTimeInterval(TimeInterval(days * 86400))
        } else {
            // If permanent, set expiration from now + days
            updatedKey.expiresAt = Date().addingTimeInterval(TimeInterval(days * 86400))
        }
        
        // Add notification
        updatedKey.notifications.append(.timeAdded(days: days))
        
        allKeys[index] = updatedKey
        
        // Update active session if this is the active key
        if activeSession?.key.id == key.id {
            activeSession = UserSession(key: updatedKey, activatedAt: activeSession!.activatedAt)
        }
        
        saveKeys()
        saveSession()
    }
    
    /// Reduce days from key
    func reduceTime(from key: UserKey, days: Int) {
        guard let index = allKeys.firstIndex(where: { $0.id == key.id }) else { return }
        guard days > 0 else { return }
        guard let currentExpiration = key.expiresAt else { return } // Can't reduce permanent keys
        
        var updatedKey = key
        
        // Reduce time
        let newExpiration = currentExpiration.addingTimeInterval(-TimeInterval(days * 86400))
        
        // Don't allow negative time (set to now if would be in past)
        updatedKey.expiresAt = max(newExpiration, Date())
        
        // Add notification
        updatedKey.notifications.append(.timeReduced(days: days))
        
        allKeys[index] = updatedKey
        
        // Update active session if this is the active key
        if activeSession?.key.id == key.id {
            activeSession = UserSession(key: updatedKey, activatedAt: activeSession!.activatedAt)
            
            // If key expired after reduction, deactivate
            if updatedKey.isExpired {
                deactivateSession()
            }
        }
        
        saveKeys()
        saveSession()
    }
    
    /// Ban a key
    func banKey(_ key: UserKey, reason: String? = nil) {
        guard let index = allKeys.firstIndex(where: { $0.id == key.id }) else { return }
        
        var updatedKey = key
        updatedKey.isBanned = true
        updatedKey.banReason = reason
        
        // Add notification
        updatedKey.notifications.append(.banned(reason: reason))
        
        allKeys[index] = updatedKey
        
        // Deactivate if this is the active key
        if activeSession?.key.id == key.id {
            deactivateSession()
        }
        
        saveKeys()
    }
    
    /// Unban a key
    func unbanKey(_ key: UserKey) {
        guard let index = allKeys.firstIndex(where: { $0.id == key.id }) else { return }
        
        var updatedKey = key
        updatedKey.isBanned = false
        updatedKey.banReason = nil
        
        // Add notification
        updatedKey.notifications.append(.unbanned)
        
        allKeys[index] = updatedKey
        saveKeys()
    }
    
    /// Clear notifications for a key
    func clearNotifications(for key: UserKey) {
        guard let index = allKeys.firstIndex(where: { $0.id == key.id }) else { return }
        
        var updatedKey = key
        updatedKey.notifications.removeAll()
        
        allKeys[index] = updatedKey
        saveKeys()
    }
    
    /// Get unread notifications count
    func unreadNotificationsCount() -> Int {
        guard let session = activeSession else { return 0 }
        return session.key.notifications.count
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
    
    /// Get all banned keys
    var bannedKeys: [UserKey] {
        return allKeys.filter { $0.isBanned }
    }
    
    // MARK: - Persistence
    
    func saveKeys() {
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
        if let session = activeSession {
            if session.key.isExpired || session.key.isBanned {
                deactivateSession()
                print("[KeyStore] Session expired or banned, deactivated")
            }
        }
    }
}

/// Key activation errors
enum KeyActivationError: LocalizedError {
    case invalidFormat
    case notFound
    case expired
    case alreadyActivated
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Formato de Key inválido. Use: JUSTINRAGEX-XXX-XXX"
        case .notFound:
            return "Key no encontrada. Verifica tu Key."
        case .expired:
            return "Esta Key ha expirado."
        case .alreadyActivated:
            return "Esta Key ya está activada en otro dispositivo."
        }
    }
}
    