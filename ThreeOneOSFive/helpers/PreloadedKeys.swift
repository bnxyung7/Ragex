import Foundation

/// Preloaded keys for specific users
struct PreloadedKeys {
    static let victorsKey = "JUSTINRAGEX-707-001"
    
    /// Initialize preloaded keys on first launch
    static func loadIfNeeded() {
        let hasLoaded = UserDefaults.standard.bool(forKey: "preloadedKeys.loaded.v1")
        guard !hasLoaded else { return }
        
        // Create Victor's key (7 days)
        let victorsUserKey = UserKey(
            keyString: victorsKey,
            duration: .sevenDays,
            userName: "VICTOR"
        )
        
        // Add to KeyStore
        var currentKeys = KeyStore.shared.allKeys
        
        // Check if key already exists
        if !currentKeys.contains(where: { $0.keyString == victorsKey }) {
            currentKeys.append(victorsUserKey)
            KeyStore.shared.allKeys = currentKeys
            KeyStore.shared.saveKeys()
        }
        
        // Mark as loaded
        UserDefaults.standard.set(true, forKey: "preloadedKeys.loaded.v1")
    }
}

