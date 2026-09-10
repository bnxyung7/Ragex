import Foundation

/// Service for communicating with Key Management API
class KeyAPIService {
    static let shared = KeyAPIService()
    
    // API base URL
    private let baseURL = "https://xkeyapi.onrender.com/api"
    
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
    }
    
    struct RemoteKeyInfo: Codable {
        let keyString: String
        let duration: String
        let userName: String?
        let expiresAt: String?
        let timeRemaining: String
        let status: String
        let isValid: Bool
    }
    
    // MARK: - Validate Key
    
    /// Validate a key against the remote API
    func validateKey(_ keyString: String) async throws -> KeyValidationResponse {
        let url = URL(string: "\(baseURL)/keys/\(keyString)/validate")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
}

// MARK: - Errors

enum KeyAPIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    
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
        }
    }
}
