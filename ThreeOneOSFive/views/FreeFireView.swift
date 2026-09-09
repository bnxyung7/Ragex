import SwiftUI

struct FreeFireView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var patchStore: PatchProjectStore
    @State private var bundlePatches: [BundlePatch] = []
    @State private var isApplying = false
    @State private var actionAlert: PatchStoreAlert?
    
    var body: some View {
        NavigationView {
            Group {
                if bundlePatches.isEmpty {
                    emptyState
                } else {
                    patchList
                }
            }
            .navigationTitle("Free Fire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppUtilityToolbar(
                    language: language,
                    onOpenSettings: {},
                    onOpenLogs: {}
                )
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            loadBundlePatches()
        }
        .alert(item: $actionAlert) { (alert: PatchStoreAlert) in
            Alert(
                title: Text(language.text(alert.titleKey)),
                message: Text(alert.message(language: language)),
                dismissButton: .default(Text(language.text("common.ok")))
            )
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No patches in bundle")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Add .3105 files to PreinstalledPatches folder")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var patchList: some View {
        List {
            Section {
                ForEach(bundlePatches) { patch in
                    patchRow(patch)
                }
            } header: {
                Text("Bundle Patches")
                    .textCase(.none)
                    .font(.headline)
            } footer: {
                Text("These patches are included in the app bundle")
                    .font(.caption)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func patchRow(_ patch: BundlePatch) -> some View {
        Button {
            applyPatch(patch)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "shippingbox.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(patch.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    if let info = patch.info {
                        Text(info)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if isApplying {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(isApplying)
    }
    
    private func loadBundlePatches() {
        let fileManager = FileManager.default
        
        guard let bundleURL = Bundle.main.resourceURL else {
            print("[FreeFire] ERROR: Could not get bundle resource URL")
            return
        }
        
        var patches: [BundlePatch] = []
        
        // Check bundle root
        if let files = try? fileManager.contentsOfDirectory(
            at: bundleURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) {
            let patchFiles = files.filter { $0.pathExtension.lowercased() == "3105" }
            patches.append(contentsOf: patchFiles.map { BundlePatch(url: $0) })
        }
        
        // Check PreinstalledPatches folder
        let preinstalledFolder = bundleURL.appendingPathComponent("PreinstalledPatches", isDirectory: true)
        if fileManager.fileExists(atPath: preinstalledFolder.path),
           let folderFiles = try? fileManager.contentsOfDirectory(
            at: preinstalledFolder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
           ) {
            let patchFiles = folderFiles.filter { $0.pathExtension.lowercased() == "3105" }
            patches.append(contentsOf: patchFiles.map { BundlePatch(url: $0) })
        }
        
        bundlePatches = patches
        print("[FreeFire] Found \(patches.count) patches in bundle")
    }
    
    private func applyPatch(_ patch: BundlePatch) {
        isApplying = true
        
        Task.detached(priority: .userInitiated) {
            do {
                // First, install the patch to library if not already there
                let fileManager = FileManager.default
                guard let destinationRoot = try? PatchProjectLibrary.packageRootURL(
                    fileManager: fileManager
                ) else {
                    throw NSError(domain: "FreeFire", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Could not access patch library"
                    ])
                }
                
                let destinationURL = destinationRoot.appendingPathComponent(patch.url.lastPathComponent)
                
                // Copy if doesn't exist
                if !fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.copyItem(at: patch.url, to: destinationURL)
                    print("[FreeFire] Copied patch to library: \(patch.displayName)")
                }
                
                // Reload patch store to pick up the new patch
                await MainActor.run {
                    patchStore.reload()
                }
                
                // Find the patch item
                let items = await MainActor.run { patchStore.items }
                guard let item = items.first(where: {
                    $0.packageURL.lastPathComponent == patch.url.lastPathComponent
                }), let project = item.project else {
                    throw NSError(domain: "FreeFire", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Patch not found after installation"
                    ])
                }
                
                // Apply the patch
                _ = try DevicePatchService.apply(project: project)
                
                await MainActor.run {
                    patchStore.reload()
                    isApplying = false
                    actionAlert = PatchStoreAlert(
                        titleKey: "common.done",
                        messageKey: "patch.applied_message"
                    )
                }
            } catch {
                await MainActor.run {
                    isApplying = false
                    actionAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: "patch.error.apply"
                    )
                }
                print("[FreeFire] Apply failed: \(error)")
            }
        }
    }
}

struct BundlePatch: Identifiable {
    let id = UUID()
    let url: URL
    
    var displayName: String {
        let filename = url.deletingPathExtension().lastPathComponent
        // Replace underscores with spaces and format nicely
        return filename.replacingOccurrences(of: "_", with: " ")
    }
    
    var info: String? {
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
