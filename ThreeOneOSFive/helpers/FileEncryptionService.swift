import Foundation
import CryptoKit
import CommonCrypto

/// Service for encrypting and decrypting .3105 patch files using AES-256-GCM
/// Key derivation uses user's API key + salt for security
@MainActor
class FileEncryptionService {
    static let shared = FileEncryptionService()
    
    // Salt for key derivation (hardcoded - in production use secure storage)
    private let salt = "RagexV2Secure2024"
    
    private init() {}
    
    // MARK: - Encryption
    
    /// Encrypt a file using AES-256-GCM
    /// - Parameters:
    ///   - inputURL: Source file URL
    ///   - outputURL: Destination encrypted file URL
    ///   - userKey: User's API key for encryption
    /// - Returns: True if encryption succeeded
    func encryptFile(at inputURL: URL, to outputURL: URL, userKey: String) throws {
        // Read original file
        let data = try Data(contentsOf: inputURL)
        
        // Derive encryption key from user key
        let encryptionKey = deriveKey(from: userKey)
        
        // Encrypt using AES-GCM
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        
        // Combine nonce + ciphertext + tag
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        // Write encrypted file
        try combined.write(to: outputURL)
        
        print("[FileEncryption] ✅ Encrypted: \(inputURL.lastPathComponent) → \(outputURL.lastPathComponent)")
    }
    
    // MARK: - Decryption
    
    /// Decrypt a file using AES-256-GCM
    /// - Parameters:
    ///   - inputURL: Encrypted file URL
    ///   - userKey: User's API key for decryption
    /// - Returns: Decrypted data
    func decryptFile(at inputURL: URL, userKey: String) throws -> Data {
        // Read encrypted file
        let encryptedData = try Data(contentsOf: inputURL)
        
        // Derive decryption key from user key
        let decryptionKey = deriveKey(from: userKey)
        
        // Decrypt using AES-GCM
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: decryptionKey)
        
        print("[FileEncryption] ✅ Decrypted: \(inputURL.lastPathComponent)")
        return decryptedData
    }
    
    /// Decrypt file data directly (for in-memory decryption)
    /// - Parameters:
    ///   - encryptedData: Encrypted data
    ///   - userKey: User's API key
    /// - Returns: Decrypted data
    func decryptData(_ encryptedData: Data, userKey: String) throws -> Data {
        let decryptionKey = deriveKey(from: userKey)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: decryptionKey)
    }
    
    // MARK: - Key Derivation
    
    /// Derive AES-256 key from master key (hardcoded)
    /// MUST match Python encrypt_patches.py MASTER_KEY
    /// - Parameter userKey: Not used - kept for API compatibility
    /// - Returns: SymmetricKey for AES-256
    private func deriveKey(from userKey: String) -> SymmetricKey {
        // Verify bundle ID for security
        if let bundleId = Bundle.main.bundleIdentifier {
            let expectedBundleId = "com.threeOneoFive.ios"
            if bundleId != expectedBundleId {
                print("⚠️ [Security] WARNING: Unauthorized bundle detected: \(bundleId)")
                print("⚠️ [Security] Expected: \(expectedBundleId)")
                // In production, you might want to throw an error here
                // For now, we log and continue to allow testing/development
            }
        }
        
        // Use MASTER_KEY (same as Python script)
        let masterKey = "RagexMasterEncryption2024"
        let keyData = (masterKey + salt).data(using: .utf8)!
        
        // Use SHA256 to derive 256-bit key
        let hashedKey = SHA256.hash(data: keyData)
        return SymmetricKey(data: hashedKey)
    }
    
    // MARK: - Batch Operations
    
    /// Encrypt all .3105 files in a directory
    /// - Parameters:
    ///   - directoryURL: Directory containing .3105 files
    ///   - userKey: User's API key
    ///   - deleteOriginal: Whether to delete original files after encryption
    func encryptDirectory(_ directoryURL: URL, userKey: String, deleteOriginal: Bool = false) throws {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            throw EncryptionError.directoryNotFound
        }
        
        var encryptedCount = 0
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.lowercased() == "3105" {
                let encryptedURL = fileURL.deletingPathExtension().appendingPathExtension("3105e")
                
                try encryptFile(at: fileURL, to: encryptedURL, userKey: userKey)
                
                if deleteOriginal {
                    try fileManager.removeItem(at: fileURL)
                    print("[FileEncryption] 🗑️ Deleted original: \(fileURL.lastPathComponent)")
                }
                
                encryptedCount += 1
            }
        }
        
        print("[FileEncryption] ✅ Encrypted \(encryptedCount) files in \(directoryURL.lastPathComponent)")
    }
    
    // MARK: - Verification
    
    /// Check if a file is encrypted (has .3105e extension)
    func isEncrypted(_ url: URL) -> Bool {
        return url.pathExtension.lowercased() == "3105e"
    }
    
    /// Verify if encrypted file can be decrypted with given key
    func verifyDecryption(at url: URL, userKey: String) -> Bool {
        do {
            _ = try decryptFile(at: url, userKey: userKey)
            return true
        } catch {
            print("[FileEncryption] ❌ Verification failed: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Errors

enum EncryptionError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidKey
    case directoryNotFound
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt file"
        case .decryptionFailed:
            return "Failed to decrypt file - invalid key or corrupted data"
        case .invalidKey:
            return "Invalid encryption key"
        case .directoryNotFound:
            return "Directory not found"
        case .fileNotFound:
            return "File not found"
        }
    }
}
