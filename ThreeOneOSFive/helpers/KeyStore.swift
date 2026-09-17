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
        syncWithServer()
        
        // Immediately sync with server when app comes to foreground
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncWithServer()
        }
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
        
        print("[KeyStore] 🔑 Generando key: \(keyString)")
        
        // Create local key first
        let key = UserKey(keyString: keyString, duration: duration, userName: userName)
        
        // Save locally immediately
        allKeys.append(key)
        saveKeys()
        
        // Send to API in background (with retry logic)
        Task {
            var attempts = 0
            let maxAttempts = 3
            
            while attempts < maxAttempts {
                do {
                    let deviceName = await MainActor.run { UIDevice.current.name }
                    _ = try await KeyAPIService.shared.createKeyFromIPA(
                        keyString: keyString,
                        duration: duration.rawValue,
                        userName: userName ?? deviceName
                    )
                    print("[KeyStore] ✅ Key registered on server: \(keyString)")
                    break
                } catch {
                    attempts += 1
                    print("[KeyStore] ⚠️ Attempt \(attempts)/\(maxAttempts) failed: \(error.localizedDescription)")
                    
                    if attempts < maxAttempts {
                        // Wait before retry (exponential backoff: 1s, 2s, 4s)
                        try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempts))) * 1_000_000_000)
                    } else {
                        print("[KeyStore] ❌ Failed to register key on server after \(maxAttempts) attempts")
                        print("[KeyStore] ℹ️ Key is still valid locally")
                    }
                }
            }
        }
        
        return key
    }
    
    /// Validate key format - supports standard JUSTINRAGEX-XXX-XXX and custom keys
    func isValidFormat(_ keyString: String) -> Bool {
        let trimmed = keyString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed.count >= 3 && trimmed.count <= 64 else { return false }
        let pattern = "^[A-Z0-9_-]{3,64}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return regex?.firstMatch(in: trimmed, options: [], range: range) != nil
    }
    
    /// Activate a key for the user (with API validation and device binding)
    func activateKey(_ keyString: String, completion: @escaping (Result<UserSession, KeyActivationError>) -> Void) {
        let cleanKey = keyString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Validate format
        guard isValidFormat(cleanKey) else {
            completion(.failure(.invalidFormat))
            return
        }
        
        let deviceId = getDeviceId()
        
        // Check if key exists locally first
        if let localKey = allKeys.first(where: { $0.keyString == cleanKey }) {
            // Ensure it's registered on server
            Task {
                await self.ensureKeyExistsOnServer(cleanKey, duration: localKey.duration)
                
                // Now proceed with normal validation
                await self.validateAndActivateRemotely(keyString: cleanKey, deviceId: deviceId, completion: completion)
            }
        } else {
            // Not a local key, just validate remotely
            Task {
                await self.validateAndActivateRemotely(keyString: cleanKey, deviceId: deviceId, completion: completion)
            }
        }
    }
    
    /// Auto-register key if it doesn't exist on server yet
    private func ensureKeyExistsOnServer(_ keyString: String, duration: KeyDuration) async {
        do {
            // Try to get key info
            _ = try await KeyAPIService.shared.getKeyInfo(keyString)
            print("[KeyStore] ✅ Key exists on server")
        } catch {
            // Key doesn't exist, create it
            print("[KeyStore] 📤 Key not found on server, registering...")
            do {
                let deviceName = await MainActor.run { UIDevice.current.name }
                _ = try await KeyAPIService.shared.createKeyFromIPA(
                    keyString: keyString,
                    duration: duration.rawValue,
                    userName: deviceName
                )
                print("[KeyStore] ✅ Key registered successfully")
            } catch {
                print("[KeyStore] ⚠️ Could not register key: \(error.localizedDescription)")
            }
        }
    }
    
    /// Helper method for remote validation and activation
    private func validateAndActivateRemotely(keyString: String, deviceId: String, completion: @escaping (Result<UserSession, KeyActivationError>) -> Void) async {
        do {
            // First validate
            let validationResult = try await KeyAPIService.shared.validateKeyWithDevice(keyString, deviceId: deviceId)
            
            await MainActor.run {
                // ⚠️ CHECK VERSION FIRST - Verificar si requiere actualización
                if let updateRequired = validationResult.updateRequired, updateRequired == true,
                   let minVersion = validationResult.minAppVersion {
                    // La key requiere una versión más nueva de la app
                    print("[KeyStore] ⚠️ Update required: Key requires version \(minVersion)")
                    
                    // Cerrar sesión activa si existe
                    if self.activeSession != nil {
                        self.deactivateSession()
                    }
                    
                    completion(.failure(.updateRequired(minVersion: minVersion)))
                    return
                }
                
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
                    let isBanned = validationResult.isBanned == true ||
                        (validationResult.reason?.lowercased().contains("bann") == true) ||
                        (validationResult.reason?.lowercased().contains("banead") == true)
                    
                    if isBanned {
                        let reason = validationResult.banReason ?? validationResult.reason ?? "Violación de términos"
                        completion(.failure(.banned(reason: reason)))
                    } else if let reason = validationResult.reason {
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
    
    private func createSession(keyString: String, completion: @escaping (Result<UserSession, KeyActivationError>) -> Void) {
        // Get key info from server FIRST
        Task {
            do {
                let remoteKey = try await KeyAPIService.shared.getKeyInfo(keyString)
                
                await MainActor.run {
                    // Parse duration and expiration from server
                    let duration = self.parseDuration(remoteKey.duration)
                    let serverExpiry = KeyStore.parseServerDate(remoteKey.expiresAt)
                    
                    // Create local key with server expiration and duration
                    let key = UserKey(keyString: keyString, duration: duration, userName: remoteKey.userName, expiresAt: serverExpiry)
                    
                    // Save locally
                    if let index = self.allKeys.firstIndex(where: { $0.keyString == keyString }) {
                        self.allKeys[index] = key
                    } else {
                        self.allKeys.append(key)
                    }
                    self.saveKeys()
                    
                    // Create session
                    let session = UserSession(key: key, activatedAt: Date())
                    self.activeSession = session
                    self.saveSession()
                    Task { @MainActor in
                        NotificationService.shared.resetExpirationNotification()
                    }
                    
                    print("[KeyStore] ✅ Session created with server duration: \(duration.rawValue)")
                    completion(.success(session))
                }
            } catch {
                await MainActor.run {
                    print("[KeyStore] ❌ Failed to get key from server: \(error)")
                    completion(.failure(.notFound))
                }
            }
        }
    }
    
    /// Parse duration string from API to KeyDuration enum
    private func parseDuration(_ durationString: String) -> KeyDuration {
        switch durationString {
        case "1H": return .oneHour
        case "3H": return .threeHours
        case "1D": return .oneDay
        case "3D": return .threeDays
        case "7D": return .sevenDays
        case "15D": return .fifteenDays
        case "30D": return .thirtyDays
        case "60D": return .sixtyDays
        case "Permanente": return .permanent
        default:
            print("[KeyStore] ⚠️ Unknown duration '\(durationString)', defaulting to 7D")
            return .sevenDays
        }
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
    
    /// Check if current active key is banned
    var isBanned: Bool {
        return activeSession?.key.isBanned == true
    }
    
    /// Get current ban reason if banned
    var banReason: String? {
        return activeSession?.key.banReason
    }
    
    // MARK: - Key Management Operations
    
    /// Reset key - kicks user out (closes session)
    func resetKey(_ key: UserKey) {
        guard let index = allKeys.firstIndex(where: { $0.id == key.id }) else { return }
        
        var updatedKey = key
        
        // Add notification
        updatedKey.notifications.append(.reset)
        
        allKeys[index] = updatedKey
        
        // KICK USER: Close session if this is the active key
        if activeSession?.key.id == key.id {
            print("[KeyStore] 🚪 Reset Key: Closing user session (kick)")
            deactivateSession()
        }
        
        saveKeys()
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
            // Load session even if expired so user retains their key view and renewal option
            activeSession = decoded
        }
    }
    
    // MARK: - Expiration Timer
    
    private var expirationTimer: Timer?
    
    private func startExpirationTimer() {
        // Check every 30 seconds for expired sessions and sync with server
        expirationTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkExpiration()
            self?.syncWithServer()
        }
        
        print("[KeyStore] ⏰ Expiration & Server Sync timer started (checks every 30s)")
    }
    
    private func checkExpiration() {
        if let session = activeSession {
            let key = session.key
            
            if let expiresAt = key.expiresAt {
                let timeLeft = expiresAt.timeIntervalSince(Date())
                
                // Warning when < 1 hour left
                if timeLeft > 0 && timeLeft < 3600 {
                    let minutesLeft = max(1, Int(timeLeft / 60))
                    print("[KeyStore] ⚠️ Key expiring soon: \(minutesLeft) minutes left")
                    Task { @MainActor in
                        NotificationService.shared.notifyExpiringSoon(minutesLeft: minutesLeft)
                    }
                }
            }
            
            // If expired, DO NOT deactivate session! Retain session and notify
            if key.isExpired {
                print("[KeyStore] ⏱ Key expired. Retaining session for renewal.")
                Task { @MainActor in
                    NotificationService.shared.notifyExpired()
                }
            }
        }
    }
    
    /// Synchronize the active session with the remote server
    func syncWithServer() {
        guard let session = activeSession else { return }
        let keyString = session.key.keyString
        let deviceId = getDeviceId()
        
        Task {
            do {
                let result = try await KeyAPIService.shared.validateKeyWithDevice(keyString, deviceId: deviceId)
                
                await MainActor.run {
                    // ⚠️ VERIFICAR VERSIÓN PRIMERO
                    if let updateRequired = result.updateRequired, updateRequired == true,
                       let minVersion = result.minAppVersion {
                        print("[KeyStore] ⚠️ Update required: Key \(keyString) requires version \(minVersion)")
                        print("[KeyStore] 🚪 Closing session due to version requirement")
                        
                        // Mostrar notificación de actualización
                        self.showUpdateRequiredAlert(minVersion: minVersion)
                        
                        // Cerrar sesión inmediatamente
                        self.deactivateSession()
                        return
                    }
                    
                    // Check if key is BANNED on server
                    let isBanned = (result.isBanned == true) ||
                        (result.reason?.lowercased().contains("bann") == true) ||
                        (result.reason?.lowercased().contains("banead") == true)
                    
                    if isBanned {
                        let reason = result.banReason ?? result.reason ?? "Clave bloqueada por administración"
                        print("[KeyStore] 🚫 Key is BANNED on server: \(keyString) - Reason: \(reason)")
                        
                        var updatedKey = session.key
                        updatedKey.isBanned = true
                        updatedKey.banReason = reason
                        
                        if !updatedKey.notifications.contains(where: {
                            if case .banned = $0 { return true } else { return false }
                        }) {
                            updatedKey.notifications.append(.banned(reason: reason))
                        }
                        
                        self.activeSession = UserSession(key: updatedKey, activatedAt: session.activatedAt)
                        self.saveSession()
                        
                        if let idx = self.allKeys.firstIndex(where: { $0.keyString == keyString }) {
                            self.allKeys[idx] = updatedKey
                            self.saveKeys()
                        }
                        return
                    }
                    
                    // IF KEY WAS RESET/KICKED OR EXPIRED ON SERVER: DEACTIVATE & KICK IMMEDIATELY!
                    if !result.valid || result.needsActivation == true {
                        print("[KeyStore] 🚪 Server kicked device or revoked key \(keyString): \(result.reason ?? "Needs activation")")
                        self.deactivateSession()
                        return
                    }
                    
                    // Update key with server data
                    var updatedKey = session.key
                    
                    // If key was previously banned locally, but server says valid now, clear ban!
                    if updatedKey.isBanned {
                        print("[KeyStore] ✅ Key unbanned on server: \(keyString)")
                        updatedKey.isBanned = false
                        updatedKey.banReason = nil
                    }
                    
                    if let remoteInfo = result.key {
                        let serverExpiry = KeyStore.parseServerDate(remoteInfo.expiresAt)
                        updatedKey.expiresAt = serverExpiry
                        if let name = remoteInfo.userName, !name.isEmpty {
                            updatedKey.userName = name
                        }
                        
                        // Check if it expired on server - DO NOT DEACTIVATE
                        if updatedKey.isExpired {
                            print("[KeyStore] ⏱ Key expired on server. Retaining session for renewal.")
                            Task { @MainActor in
                                NotificationService.shared.notifyExpired()
                            }
                        }
                    }
                    
                    // Save updated session
                    self.activeSession = UserSession(key: updatedKey, activatedAt: session.activatedAt)
                    self.saveSession()
                    
                    // Update allKeys
                    if let idx = self.allKeys.firstIndex(where: { $0.keyString == keyString }) {
                        self.allKeys[idx] = updatedKey
                        self.saveKeys()
                    }
                    
                    print("[KeyStore] 🔄 Synced with server: expiration = \(String(describing: updatedKey.expiresAt))")
                }
            } catch {
                print("[KeyStore] ⚠️ Server sync check failed (will retry): \(error.localizedDescription)")
            }
        }
    }
    
    /// Show alert when app update is required
    private func showUpdateRequiredAlert(minVersion: String) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }
            
            let alert = UIAlertController(
                title: "⚠️ ACTUALIZACIÓN REQUERIDA",
                message: "Esta Key requiere la versión \(minVersion) o superior de la app.\n\nTu sesión ha sido cerrada.\n\nDescarga la última versión para continuar usando esta Key.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Entendido", style: .default))
            
            rootViewController.present(alert, animated: true)
        }
    }
    
    /// Parse date string from server in various ISO formats
    static func parseServerDate(_ dateString: String?) -> Date? {
        guard let str = dateString, !str.isEmpty else { return nil }
        
        let isoWithFractional = ISO8601DateFormatter()
        isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFractional.date(from: str) {
            return date
        }
        
        let simpleIso = ISO8601DateFormatter()
        if let date = simpleIso.date(from: str) {
            return date
        }
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for fmt in formats {
            df.dateFormat = fmt
            if let date = df.date(from: str) {
                return date
            }
        }
        
        return nil
    }
}

/// Key activation errors
enum KeyActivationError: LocalizedError {
    case invalidFormat
    case notFound
    case expired
    case alreadyActivated
    case banned(reason: String?)
    case updateRequired(minVersion: String)  // Nueva versión requerida
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Clave inválida. Introduce tu Key asignada."
        case .notFound:
            return "Key no encontrada. Verifica tu Key."
        case .expired:
            return "Esta Key ha expirado."
        case .alreadyActivated:
            return "Esta Key ya está activada en otro dispositivo."
        case .banned(let reason):
            return "Esta Key ha sido BANEADA: \(reason ?? "Uso indebido")"
        case .updateRequired(let minVersion):
            return "⚠️ ACTUALIZACIÓN REQUERIDA\n\nEsta Key requiere la versión \(minVersion) o superior.\n\nDescarga la última versión de la app para usar esta Key."
        }
    }
}
    