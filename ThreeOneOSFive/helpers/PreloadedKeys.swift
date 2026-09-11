import Foundation

/// Preloaded keys - Default keys for users
struct PreloadedKeys {
    /// Initialize preloaded keys on first launch
    static func loadIfNeeded() {
        let keyStore = KeyStore.shared
        
        // Check if already loaded
        let loadedKey = "preloaded_keys_v2_loaded"
        if UserDefaults.standard.bool(forKey: loadedKey) {
            return
        }
        
        print("[PreloadedKeys] 🔑 Loading default keys...")
        
        // Create permanent keys for all users
        let defaultKeys = [
            ("JUSTINRAGEX-000-001", KeyDuration.permanent, "Default User 1"),
            ("JUSTINRAGEX-000-002", KeyDuration.permanent, "Default User 2"),
            ("JUSTINRAGEX-000-003", KeyDuration.permanent, "Default User 3"),
            ("JUSTINRAGEX-999-999", KeyDuration.permanent, "VIP Access")
        ]
        
        for (keyString, duration, userName) in defaultKeys {
            // Check if key already exists
            if keyStore.allKeys.contains(where: { $0.keyString == keyString }) {
                print("[PreloadedKeys] ⏭️ Key \(keyString) already exists, skipping")
                continue
            }
            
            // Create the key
            let key = UserKey(keyString: keyString, duration: duration, userName: userName)
            keyStore.allKeys.append(key)
            print("[PreloadedKeys] ✅ Created key: \(keyString) (\(userName))")
        }
        
        keyStore.saveKeys()
        UserDefaults.standard.set(true, forKey: loadedKey)
        
        print("[PreloadedKeys] 🎉 Default keys loaded successfully!")
        print("[PreloadedKeys] 📝 Users can activate any of these keys:")
        print("[PreloadedKeys]    - JUSTINRAGEX-000-001")
        print("[PreloadedKeys]    - JUSTINRAGEX-000-002")
        print("[PreloadedKeys]    - JUSTINRAGEX-000-003")
        print("[PreloadedKeys]    - JUSTINRAGEX-999-999 (VIP)")
    }
}
