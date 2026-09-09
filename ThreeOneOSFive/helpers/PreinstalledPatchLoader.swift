import Foundation

/// Loads preinstalled patches from the app bundle on first launch
enum PreinstalledPatchLoader {
    private static let hasInstalledKey = "PreinstalledPatchLoader.hasInstalled"
    
    /// Install preinstalled patches from bundle if not already done
    static func installIfNeeded() {
        print("[PreinstalledPatches] Checking if installation needed...")
        
        guard !UserDefaults.standard.bool(forKey: hasInstalledKey) else {
            print("[PreinstalledPatches] Already installed, skipping")
            return // Already installed
        }
        
        print("[PreinstalledPatches] First launch detected, installing patches...")
        installPreinstalledPatches()
        UserDefaults.standard.set(true, forKey: hasInstalledKey)
        print("[PreinstalledPatches] Installation complete")
    }
    
    private static func installPreinstalledPatches() {
        let fileManager = FileManager.default
        
        print("[PreinstalledPatches] Looking for bundle patches folder...")
        
        // Get bundle directory with preinstalled patches
        guard let bundlePatchesURL = Bundle.main.url(
            forResource: "PreinstalledPatches",
            withExtension: nil
        ) else {
            print("[PreinstalledPatches] ERROR: PreinstalledPatches folder not found in bundle")
            return // No preinstalled patches folder
        }
        
        print("[PreinstalledPatches] Found folder at: \(bundlePatchesURL.path)")
        
        // Get destination directory
        guard let destinationRoot = try? PatchProjectLibrary.packageRootURL(
            fileManager: fileManager
        ) else {
            print("[PreinstalledPatches] ERROR: Could not get patch library destination")
            return
        }
        
        print("[PreinstalledPatches] Destination: \(destinationRoot.path)")
        
        // Get all .xpatch files from bundle
        guard let patchFiles = try? fileManager.contentsOfDirectory(
            at: bundlePatchesURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ).filter({ $0.pathExtension.lowercased() == "xpatch" }) else {
            print("[PreinstalledPatches] ERROR: Could not read bundle patches folder")
            return
        }
        
        print("[PreinstalledPatches] Found \(patchFiles.count) .xpatch files")
        
        // Copy each patch to destination
        for sourceURL in patchFiles {
            let destinationURL = destinationRoot.appendingPathComponent(
                sourceURL.lastPathComponent
            )
            
            // Skip if already exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                print("[PreinstalledPatches] Skipping (already exists): \(sourceURL.lastPathComponent)")
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
