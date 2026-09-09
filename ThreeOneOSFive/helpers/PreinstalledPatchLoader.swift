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
    
    /// Force reinstall preinstalled patches (bypasses the "already installed" check)
    static func forceReinstall() {
        print("[PreinstalledPatches] Force reinstall requested...")
        installPreinstalledPatches()
        print("[PreinstalledPatches] Force reinstall complete")
    }
    
    private static func installPreinstalledPatches() {
        let fileManager = FileManager.default
        
        print("[PreinstalledPatches] Looking for patch file in bundle...")
        
        // Try to find the .xpatch file directly in the bundle
        guard let bundleURL = Bundle.main.resourceURL else {
            print("[PreinstalledPatches] ERROR: Could not get bundle resource URL")
            return
        }
        
        print("[PreinstalledPatches] Bundle resource URL: \(bundleURL.path)")
        
        // Look for .xpatch files in bundle
        guard let allFiles = try? fileManager.contentsOfDirectory(
            at: bundleURL,
            includingPropertiesForKeys: nil,
            options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
        ) else {
            print("[PreinstalledPatches] ERROR: Could not list bundle contents")
            return
        }
        
        let patchFiles = allFiles.filter { $0.pathExtension.lowercased() == "xpatch" }
        print("[PreinstalledPatches] Found \(patchFiles.count) .xpatch files in bundle root")
        
        // Also check PreinstalledPatches subfolder
        let preinstalledFolder = bundleURL.appendingPathComponent("PreinstalledPatches", isDirectory: true)
        var additionalPatches: [URL] = []
        
        if fileManager.fileExists(atPath: preinstalledFolder.path) {
            print("[PreinstalledPatches] Found PreinstalledPatches folder")
            if let folderFiles = try? fileManager.contentsOfDirectory(
                at: preinstalledFolder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                additionalPatches = folderFiles.filter { $0.pathExtension.lowercased() == "xpatch" }
                print("[PreinstalledPatches] Found \(additionalPatches.count) .xpatch files in PreinstalledPatches folder")
            }
        } else {
            print("[PreinstalledPatches] PreinstalledPatches folder not found at: \(preinstalledFolder.path)")
        }
        
        let allPatchFiles = patchFiles + additionalPatches
        
        guard !allPatchFiles.isEmpty else {
            print("[PreinstalledPatches] No .xpatch files found in bundle")
            return
        }
        
        // Get destination directory
        guard let destinationRoot = try? PatchProjectLibrary.packageRootURL(
            fileManager: fileManager
        ) else {
            print("[PreinstalledPatches] ERROR: Could not get patch library destination")
            return
        }
        
        print("[PreinstalledPatches] Destination: \(destinationRoot.path)")
        
        // Copy each patch to destination
        for sourceURL in allPatchFiles {
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
                print("[PreinstalledPatches] ✅ Installed: \(sourceURL.lastPathComponent)")
            } catch {
                print("[PreinstalledPatches] ❌ Failed to install \(sourceURL.lastPathComponent): \(error)")
            }
        }
    }
    
    /// Reset the flag (for testing)
    static func resetInstallationFlag() {
        UserDefaults.standard.removeObject(forKey: hasInstalledKey)
    }
}
