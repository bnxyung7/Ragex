import Foundation

/// Loads preinstalled patches from the app bundle on first launch
enum PreinstalledPatchLoader {
    private static let hasInstalledKey = "PreinstalledPatchLoader.hasInstalled"
    
    /// Install preinstalled patches from bundle if not already done
    static func installIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: hasInstalledKey) else {
            return // Already installed
        }
        
        installPreinstalledPatches()
        UserDefaults.standard.set(true, forKey: hasInstalledKey)
    }
    
    private static func installPreinstalledPatches() {
        let fileManager = FileManager.default
        
        // Get bundle directory with preinstalled patches
        guard let bundlePatchesURL = Bundle.main.url(
            forResource: "PreinstalledPatches",
            withExtension: nil
        ) else {
            return // No preinstalled patches folder
        }
        
        // Get destination directory
        guard let destinationRoot = try? PatchProjectLibrary.packageRootURL(
            fileManager: fileManager
        ) else {
            return
        }
        
        // Get all .xpatch files from bundle
        guard let patchFiles = try? fileManager.contentsOfDirectory(
            at: bundlePatchesURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ).filter({ $0.pathExtension.lowercased() == "xpatch" }) else {
            return
        }
        
        // Copy each patch to destination
        for sourceURL in patchFiles {
            let destinationURL = destinationRoot.appendingPathComponent(
                sourceURL.lastPathComponent
            )
            
            // Skip if already exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                continue
            }
            
            do {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                print("[PreinstalledPatches] Installed: \(sourceURL.lastPathComponent)")
            } catch {
                print("[PreinstalledPatches] Failed to install \(sourceURL.lastPathComponent): \(error)")
            }
        }
    }
    
    /// Reset the flag (for testing)
    static func resetInstallationFlag() {
        UserDefaults.standard.removeObject(forKey: hasInstalledKey)
    }
}
