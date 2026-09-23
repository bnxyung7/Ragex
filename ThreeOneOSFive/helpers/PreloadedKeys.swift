import Foundation

/// PreloadedKeys — stub vacío.
/// Las keys pre-cargadas han sido eliminadas.
/// Toda activación debe pasar por el servidor (KeyAPIService).
struct PreloadedKeys {
    static func loadIfNeeded() {
        // Eliminar cualquier key pre-cargada que haya quedado de versiones anteriores
        let legacyKey = "preloaded_keys_v2_loaded"
        let legacyKeyStrings: Set<String> = [
            "JUSTINRAGEX-000-001",
            "JUSTINRAGEX-000-002",
            "JUSTINRAGEX-000-003",
            "JUSTINRAGEX-999-999"
        ]

        let keyStore = KeyStore.shared

        // Purge legacy keys from local store
        let before = keyStore.allKeys.count
        keyStore.allKeys.removeAll { legacyKeyStrings.contains($0.keyString) }
        let removed = before - keyStore.allKeys.count

        if removed > 0 {
            keyStore.saveKeys()
            print("[PreloadedKeys] 🗑️ Removed \(removed) legacy pre-loaded key(s)")

            // If the active session was one of the legacy keys, deactivate it
            if let active = keyStore.activeSession,
               legacyKeyStrings.contains(active.key.keyString) {
                keyStore.deactivateSession()
                print("[PreloadedKeys] 🚪 Deactivated legacy session")
            }
        }

        // Clear the "already loaded" flag so purge runs once more if needed
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }
}
