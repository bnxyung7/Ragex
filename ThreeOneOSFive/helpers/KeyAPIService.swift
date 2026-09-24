import Foundation

/// Service for communicating with Key Management API
class KeyAPIService {
    static let shared = KeyAPIService()
    
    // API base URLs
    private let baseURL = "https://xkeyapi.onrender.com/api" // Keys API (legacy)
    private let adminPanelURL = "https://xkeyapi.onrender.com/api"  // Admin Panel
    
    // API authorization token
    private let apiToken = "xkey_admin_secret_token_2026"
    
    private init() {}
    
    // MARK: - API Response Models
    
    struct APIResponse<T: Codable>: Codable {
        let success: Bool
        let data: T?
        let error: String?
    }
    
    struct KeyValidationResponse: Codable {
        let valid: Bool
        let reason: String?
        let key: RemoteKeyInfo?
        let needsActivation: Bool?
        let message: String?
        let isBanned: Bool?
        let banReason: String?
        let blockType: String?
        let title: String?
        let minAppVersion: String?  // Minimum app version required for this key
        let updateRequired: Bool?    // If true, user must update to use this key
    }
    
    struct RemoteKeyInfo: Codable {
        let keyString: String
        let duration: String
        let userName: String?
        let expiresAt: String?
        let timeRemaining: String
        let status: String?
        let isValid: Bool?
    }
    
    struct CreateKeyResponse: Codable {
        let success: Bool
        let message: String
        let key: RemoteKeyInfo
    }
    
    // MARK: - Create Key
    
    /// Create a new key directly from the IPA (for first-time installations)
    /// This method is designed to be called when generating keys within the app
    func createKeyFromIPA(keyString: String, duration: String = "Permanente", userName: String? = nil) async throws -> RemoteKeyInfo {
        let url = URL(string: "\(baseURL)/keys/create")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiToken, forHTTPHeaderField: "X-API-Token")
        request.timeoutInterval = 30
        
        var body: [String: Any] = [
            "keyString": keyString,
            "duration": duration
        ]
        
        if let userName = userName {
            body["userName"] = userName
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KeyAPIError.invalidResponse
        }
        
        // Si la key ya existe (409), obtener su info en lugar de fallar
        if httpResponse.statusCode == 409 {
            print("⚠️ Key already exists in API, fetching info...")
            return try await getKeyInfo(keyString)
        }
        
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw KeyAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let createResponse = try decoder.decode(CreateKeyResponse.self, from: data)
        
        print("✅ Key created on server: \(createResponse.key.keyString)")
        return createResponse.key
    }
    
    /// Create a new key on the server (legacy method for backward compatibility)
    func createKeyOnServer(keyString: String, duration: String, userName: String?) async throws {
        let url = URL(string: "\(baseURL)/keys/create")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiToken, forHTTPHeaderField: "X-API-Token")
        
        // Build request body
        var body: [String: Any] = [
            "duration": duration
        ]
        
        if let userName = userName {
            body["userName"] = userName
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KeyAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw KeyAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Decode response to verify success
        let decoder = JSONDecoder()
        let createResponse = try decoder.decode(CreateKeyResponse.self, from: data)
        
        if !createResponse.success {
            throw KeyAPIError.invalidResponse
        }
    }
    
    // MARK: - Validate Key
    
    /// Validate a key with device ID
    func validateKeyWithDevice(_ keyString: String, deviceId: String) async throws -> KeyValidationResponse {
        let cleanKey = keyString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let encodedKey = cleanKey.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw KeyAPIError.invalidResponse
        }
        let url = URL(string: "\(baseURL)/keys/\(encodedKey)/validate")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String 
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String 
            ?? "3.1.5"
        request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        request.timeoutInterval = 15
        
        let regionCode = Locale.current.region?.identifier ?? ""
        var body: [String: Any] = [
            "country": regionCode,
            "countryCode": regionCode,
            "appVersion": appVersion
        ]
        DeviceIdentity.requestFields().forEach { body[$0.key] = $0.value }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KeyAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = errorObj["error"] as? String ?? errorObj["message"] as? String {
                throw KeyAPIError.serverMessage(msg)
            }
            throw KeyAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let validationResponse = try decoder.decode(KeyValidationResponse.self, from: data)
        
        return validationResponse
    }
    
    /// Activate a key with device ID
    func activateKey(_ keyString: String, deviceId: String) async throws {
        let cleanKey = keyString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let encodedKey = cleanKey.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw KeyAPIError.invalidResponse
        }
        let url = URL(string: "\(baseURL)/keys/\(encodedKey)/activate")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String 
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String 
            ?? "3.1.5"
        request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        request.timeoutInterval = 15
        
        let activateRegionCode = Locale.current.region?.identifier ?? ""
        var activateBody: [String: Any] = [
            "country": activateRegionCode,
            "countryCode": activateRegionCode,
            "appVersion": appVersion
        ]
        DeviceIdentity.requestFields().forEach { activateBody[$0.key] = $0.value }
        request.httpBody = try JSONSerialization.data(withJSONObject: activateBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KeyAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let msg = (errorObj["reason"] as? String)
                    ?? (errorObj["banReason"] as? String)
                    ?? (errorObj["error"] as? String)
                    ?? (errorObj["message"] as? String)
                if let msg, !msg.isEmpty {
                    throw KeyAPIError.serverMessage(msg)
                }
            }
            throw KeyAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Verify success from JSON
        if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = jsonResponse["success"] as? Bool, !success {
            let msg = jsonResponse["error"] as? String ?? jsonResponse["message"] as? String ?? "Error al activar"
            throw KeyAPIError.serverMessage(msg)
        }
    }
    
    /// Validate a key against the remote API (legacy, no device ID)
    func validateKey(_ keyString: String) async throws -> KeyValidationResponse {
        let url = URL(string: "\(baseURL)/keys/\(keyString)/validate")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String 
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String 
            ?? "3.1.5"
        request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        var body: [String: Any] = [
            "appVersion": appVersion
        ]
        DeviceIdentity.requestFields().forEach { body[$0.key] = $0.value }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KeyAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw KeyAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let validationResponse = try decoder.decode(KeyValidationResponse.self, from: data)
        
        return validationResponse
    }
    
    // MARK: - Get Key Info
    
    /// Get detailed key information
    func getKeyInfo(_ keyString: String) async throws -> RemoteKeyInfo {
        let url = URL(string: "\(baseURL)/keys/\(keyString)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KeyAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw KeyAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        
        struct GetKeyResponse: Codable {
            let success: Bool
            let key: RemoteKeyInfo
        }
        
        let keyResponse = try decoder.decode(GetKeyResponse.self, from: data)
        
        return keyResponse.key
    }
    
    // MARK: - Health Check
    
    /// Check if API is online
    func healthCheck() async throws -> Bool {
        let url = URL(string: "\(baseURL)/health")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        
        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                return status == "ok"
            }
        }
        
        return false
    }
    
    // MARK: - Sync with API
    
    /// Validate key both locally and remotely
    func validateKeyHybrid(_ keyString: String) async -> (isValid: Bool, source: String, message: String) {
        // Try remote validation first
        do {
            let response = try await validateKey(keyString)
            
            if response.valid {
                return (true, "remote", "Key validated with server")
            } else {
                return (false, "remote", response.reason ?? "Key invalid")
            }
        } catch {
            print("[KeyAPI] Remote validation failed: \(error.localizedDescription)")
            
            // Fallback to local validation
            let localStore = KeyStore.shared
            if let localKey = localStore.allKeys.first(where: { $0.keyString == keyString }) {
                if localKey.isValid {
                    return (true, "local", "Key validated locally (offline)")
                } else if localKey.isBanned {
                    return (false, "local", "Key is banned")
                } else if localKey.isExpired {
                    return (false, "local", "Key has expired")
                }
            }
            
            return (false, "local", "Key not found")
        }
    }

    // MARK: - Push Notifications

    /// Register (or update) the APNs device token on the server.
    /// The server stores { token, keyString, platform } so the admin
    /// web panel can target specific users or broadcast to all devices.
    func registerDevicePushToken(token: String, keyString: String) async throws {
        let url = URL(string: "\(baseURL)/push/register")!

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"  // Cambiado de POST a PUT para registro/actualización
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiToken, forHTTPHeaderField: "X-API-Token")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "token": token,
            "keyString": keyString,
            "deviceId": DeviceIdentity.stableId(),
            "platform": "apns"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 || http.statusCode == 201 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            // Si es 405 (Method Not Allowed), el servidor no soporta este endpoint aún
            // Tratarlo como no-fatal ya que no es crítico para la funcionalidad principal
            if code == 405 {
                print("[Push] ⚠️ Server does not support push token registration (405) — will skip")
                return  // Exit gracefully without throwing
            }
            throw KeyAPIError.httpError(statusCode: code)
        }
    }

    /// Send a push notification broadcast from the admin panel.
    /// - Parameters:
    ///   - title:     Notification title
    ///   - message:   Notification body
    ///   - keyString: Target key string, or "ALL" to broadcast to every device
    ///   - linkURL:   Optional deep-link URL included in push payload
    ///   - linkTitle: Human-readable label for the link button
    ///   - isUrgent:  If true, the app displays a warning-style toast
    func sendPushBroadcast(
        title: String,
        message: String,
        keyString: String = "ALL",
        linkURL: String? = nil,
        linkTitle: String? = nil,
        isUrgent: Bool = false
    ) async throws {
        let url = URL(string: "\(baseURL)/push/send")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiToken, forHTTPHeaderField: "X-API-Token")
        request.timeoutInterval = 20

        var body: [String: Any] = [
            "title":     title,
            "message":   message,
            "keyString": keyString,
            "urgent":    isUrgent
        ]
        if let linkURL   = linkURL   { body["linkURL"]   = linkURL }
        if let linkTitle = linkTitle { body["linkTitle"] = linkTitle }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 || http.statusCode == 201 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            // Try to surface the server error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errMsg = json["error"] as? String {
                throw KeyAPIError.serverMessage(errMsg)
            }
            throw KeyAPIError.httpError(statusCode: code)
        }
    }

    /// Post a notification message to the server's notification feed
    /// (shows up in NotificationsCenter via the polling endpoint).
    func postAdminNotification(
        title: String,
        message: String,
        linkURL: String? = nil,
        linkTitle: String? = nil,
        isUrgent: Bool = false
    ) async throws {
        let url = URL(string: "\(baseURL)/notifications")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiToken, forHTTPHeaderField: "X-API-Token")
        request.timeoutInterval = 15

        var body: [String: Any] = [
            "title":    title,
            "message":  message,
            "isUrgent": isUrgent
        ]
        if let linkURL   = linkURL   { body["linkURL"]   = linkURL }
        if let linkTitle = linkTitle { body["linkTitle"] = linkTitle }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 || http.statusCode == 201 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw KeyAPIError.httpError(statusCode: code)
        }
    }
    
    // MARK: - IPA Version Management
    
    /// Obtener la última versión activa de un IPA desde el panel admin
    func getLatestIPAVersion(appName: String) async throws -> IPAVersionInfo {
        let url = URL(string: "\(adminPanelURL)/ipa/latest/\(appName)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw KeyAPIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            throw KeyAPIError.httpError(statusCode: http.statusCode)
        }
        
        let decoder = JSONDecoder()
        let versionResponse = try decoder.decode(IPAVersionResponse.self, from: data)
        
        guard versionResponse.success else {
            throw KeyAPIError.serverMessage(versionResponse.message ?? "No active version")
        }
        
        return versionResponse.version
    }
    
    // MARK: - Version Control (Force Update)
    
    struct VersionStatusResponse: Codable {
        let isAllowed: Bool
        let currentVersion: String
        let minimumVersion: String?
        let latestVersion: String?
        let forceUpdate: Bool
        let message: String?
        let downloadURL: String?
    }
    
    /// Check if current app version is allowed to run
    /// Returns: (isAllowed, minimumVersion, forceUpdateMessage)
    func checkVersionStatus() async throws -> VersionStatusResponse {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
        let appName = "X" // Bundle name
        
        let url = URL(string: "\(self.adminPanelURL)/version/check")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiToken, forHTTPHeaderField: "X-API-Token")
        request.timeoutInterval = 10
        
        let body: [String: Any] = [
            "appName": appName,
            "currentVersion": currentVersion,
            "platform": "iOS"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw KeyAPIError.invalidResponse
        }
        
        // If endpoint doesn't exist (404/405), allow by default
        if http.statusCode == 404 || http.statusCode == 405 {
            print("[VersionCheck] ⚠️ Endpoint not implemented, allowing by default")
            return VersionStatusResponse(
                isAllowed: true,
                currentVersion: currentVersion,
                minimumVersion: nil,
                latestVersion: nil,
                forceUpdate: false,
                message: nil,
                downloadURL: nil
            )
        }
        guard (200..<300).contains(http.statusCode) else {
            throw KeyAPIError.httpError(statusCode: http.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(VersionStatusResponse.self, from: data)
    }

    // MARK: - Error Telemetry Reporting

    /// Report execution error or patch error to server
    func reportExecutionError(
        keyString: String?,
        action: String,
        targetBundle: String? = nil,
        errorMessage: String
    ) async {
        guard let url = URL(string: "\(baseURL)/logs/report") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiToken, forHTTPHeaderField: "X-API-Token")
        request.timeoutInterval = 10
        
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String 
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String 
            ?? "3.1.5"
        let iosVersion = "\(AppInfo.osVersion) (\(AppInfo.osBuild))"
        let deviceModel = AppInfo.hardwareDisplayName
        let deviceId = DeviceIdentity.stableId()
        
        let body: [String: Any] = [
            "keyString": keyString ?? "",
            "deviceId": deviceId,
            "action": action,
            "targetBundle": targetBundle ?? "",
            "errorMessage": errorMessage,
            "appVersion": appVersion,
            "iosVersion": iosVersion,
            "deviceModel": deviceModel
        ]
        
        if let bodyData = try? JSONSerialization.data(withJSONObject: body) {
            request.httpBody = bodyData
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}

// MARK: - IPA Version Models

struct IPAVersionResponse: Codable {
    let success: Bool
    let message: String?
    let version: IPAVersionInfo
}

struct IPAVersionInfo: Codable {
    let id: Int
    let appName: String
    let version: String
    let fileName: String
    let fileSize: Int
    let uploadDate: Int
    let isActive: Int
    let downloadCount: Int
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case appName = "app_name"
        case version
        case fileName = "file_name"
        case fileSize = "file_size"
        case uploadDate = "upload_date"
        case isActive = "is_active"
        case downloadCount = "download_count"
        case notes
    }
    
    var downloadURL: String {
        "https://xkeyapi.onrender.com/api/ipa/download/\(id)"
    }
    
    var formattedSize: String {
        let mb = Double(fileSize) / 1024 / 1024
        return String(format: "%.2f MB", mb)
    }
}

// MARK: - Errors

enum KeyAPIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverMessage(let msg):
            return msg
        }
    }
    
}
