import Foundation

/// Loads preinstalled patches from the app bundle on first launch
enum BundlePack {
    static let rootName = "zh-Hans.lproj"
    static let normalPack = "4"
    static let maxPack = "8"
    private static let mask: [UInt8] = [0x6D, 0x31, 0xA4, 0x59]

    static func isWrapped(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "strings"
    }

    static func packageName(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if ext == "strings" || ext == "3105e" {
            var stem = url.deletingPathExtension().lastPathComponent
            if !stem.hasSuffix(".3105") {
                stem += ".3105"
            }
            return stem
        }
        return url.lastPathComponent
    }

    static func plainData(at url: URL) throws -> Data {
        let raw = try Data(contentsOf: url)
        guard isWrapped(url) else { return raw }
        var out = Data(count: raw.count)
        raw.withUnsafeBytes { src in
            out.withUnsafeMutableBytes { dst in
                let s = src.bindMemory(to: UInt8.self)
                let d = dst.bindMemory(to: UInt8.self)
                for i in 0..<raw.count {
                    d[i] = s[i] ^ mask[i % mask.count]
                }
            }
        }
        return out
    }
}

enum PackInstall {
    private static let installedGenerationKey = "pack.generation"
    private static let generation = "3.1.6-29b"

    /// Copy bundled patches once per build. An empty bundle does not lock the flag,
    /// so a later IPA that adds products still installs them.
    static func installIfNeeded() {
        if UserDefaults.standard.string(forKey: installedGenerationKey) == generation {
            return
        }
        if installPack() {
            UserDefaults.standard.set(generation, forKey: installedGenerationKey)
        } else {
            UserDefaults.standard.removeObject(forKey: installedGenerationKey)
        }
    }
    
    /// Force reinstall preinstalled patches (bypasses the "already installed" check)
    static func forceReinstall() {
        installPack()
    }
    
    @discardableResult
    private static func installPack() -> Bool {
        let fileManager = FileManager.default
        
        guard let bundleURL = Bundle.main.resourceURL else {
            return false
        }
        
        guard let allFiles = try? fileManager.contentsOfDirectory(
            at: bundleURL,
            includingPropertiesForKeys: nil,
            options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
        ) else {
            return false
        }
        
        let patchFiles = allFiles.filter { ["3105", "3105e", "strings"].contains($0.pathExtension.lowercased()) }
        
        let preinstalledFolder = bundleURL.appendingPathComponent(BundlePack.rootName, isDirectory: true)
        var additionalPatches: [URL] = []
        
        if fileManager.fileExists(atPath: preinstalledFolder.path) {
            if let enumerator = fileManager.enumerator(at: preinstalledFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if ["3105", "3105e", "strings"].contains(fileURL.pathExtension.lowercased()) {
                        additionalPatches.append(fileURL)
                    }
                }
            }
        }
        
        let allPatchFiles = patchFiles + additionalPatches
        
        guard !allPatchFiles.isEmpty else {
            return false
        }
        
        guard let destinationRoot = try? PatchProjectLibrary.packageRootURL(
            fileManager: fileManager
        ) else {
            return false
        }
        
        for sourceURL in allPatchFiles {
            let destinationURL = destinationRoot.appendingPathComponent(
                BundlePack.packageName(for: sourceURL)
            )
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                try? fileManager.removeItem(at: destinationURL)
            }
            
            do {
                if BundlePack.isWrapped(sourceURL) {
                    let plain = try BundlePack.plainData(at: sourceURL)
                    try plain.write(to: destinationURL, options: .atomic)
                } else {
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                }
            } catch {
                return false
            }
        }
        return true
    }
    
    /// Reset the flag (for testing)
    static func resetInstallationFlag() {
        UserDefaults.standard.removeObject(forKey: installedGenerationKey)
    }
}
