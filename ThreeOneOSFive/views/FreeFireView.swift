import SwiftUI

struct FreeFireView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var patchStore: PatchProjectStore
    @StateObject private var keyStore = KeyStore.shared
    @State private var bundlePatches: [BundlePatch] = []
    @State private var selectedCategory: PatchCategory = .aimbot
    @State private var isApplying = false
    @State private var actionAlert: PatchStoreAlert?
    @State private var selectedPatch: BundlePatch?
    @State private var showPatchControl = false
    
    enum PatchCategory: String, CaseIterable, Identifiable {
        case aimbot = "AIMBOT"
        case holograma = "HOLOGRAMA"
        case others = "OTHERS"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .aimbot: return "scope"
            case .holograma: return "cube.transparent"
            case .others: return "ellipsis.circle"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if keyStore.hasValidAccess() {
                    // User has valid Key - show content
                    VStack(spacing: 0) {
                        // Category selector
                        categoryPicker
                        
                        // Patch list
                        Group {
                            if filteredPatches.isEmpty {
                                emptyState
                            } else {
                                patchList
                            }
                        }
                    }
                } else {
                    // No valid Key - show locked state
                    lockedView
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
        .sheet(isPresented: $showPatchControl) {
            if let patch = selectedPatch {
                PatchControlBottomSheet(patch: patch)
                    .environmentObject(patchStore)
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.hidden)
            }
        }
    }
    
    // MARK: - Locked View
    
    private var lockedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Lock icon
            Image(systemName: "lock.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
            
            // Title
            Text("Free Fire Bloqueado")
                .font(.title2)
                .fontWeight(.bold)
            
            // Message
            Text("Free Fire está bloqueado. Activa tu Key desde Perfil.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Info box
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("¿Cómo activar?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Ve a la pestaña Perfil e introduce tu Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PatchCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(category.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? AppTheme.accent : Color(.systemGray5))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    private var filteredPatches: [BundlePatch] {
        bundlePatches.filter { $0.category == selectedCategory }
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
                ForEach(filteredPatches) { patch in
                    patchRow(patch)
                }
            } header: {
                Text(selectedCategory.rawValue)
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
            openPatchControl(patch)
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
        var seenFilenames = Set<String>()
        
        // Check PreinstalledPatches folder ONLY (not bundle root to avoid duplicates)
        let preinstalledFolder = bundleURL.appendingPathComponent("PreinstalledPatches", isDirectory: true)
        if fileManager.fileExists(atPath: preinstalledFolder.path),
           let folderFiles = try? fileManager.contentsOfDirectory(
            at: preinstalledFolder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
           ) {
            let patchFiles = folderFiles.filter { $0.pathExtension.lowercased() == "3105" }
            for url in patchFiles {
                let filename = url.lastPathComponent
                if !seenFilenames.contains(filename) {
                    seenFilenames.insert(filename)
                    patches.append(BundlePatch(url: url))
                }
            }
        }
        
        bundlePatches = patches
        print("[FreeFire] Found \(patches.count) unique patches in bundle")
    }
    
    private func openPatchControl(_ patch: BundlePatch) {
        // First ensure patch is in library
        Task {
            do {
                let fileManager = FileManager.default
                guard let destinationRoot = try? PatchProjectLibrary.packageRootURL(
                    fileManager: fileManager
                ) else {
                    return
                }
                
                let destinationURL = destinationRoot.appendingPathComponent(patch.url.lastPathComponent)
                
                // Copy if doesn't exist
                if !fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.copyItem(at: patch.url, to: destinationURL)
                    print("[FreeFire] Copied patch to library: \(patch.displayName)")
                    
                    // Reload patch store
                    await MainActor.run {
                        patchStore.reload()
                    }
                }
                
                await MainActor.run {
                    selectedPatch = patch
                    showPatchControl = true
                }
            } catch {
                print("[FreeFire] Error preparing patch: \(error)")
            }
        }
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
        // Replace underscores with spaces
        var name = filename.replacingOccurrences(of: "_", with: " ")
        
        // Replace PERCENT with %
        name = name.replacingOccurrences(of: " PERCENT", with: "%")
        
        // Remove existing percentage if present (like "70" at end)
        if let lastWord = name.split(separator: " ").last,
           lastWord.allSatisfy({ $0.isNumber }) {
            name = name.replacingOccurrences(of: " \(lastWord)", with: "")
        }
        
        // Always add 70% at the end if not already there
        if !name.hasSuffix("%") {
            return "\(name) 70%"
        }
        
        return name
    }
    
    var category: FreeFireView.PatchCategory {
        let filename = url.lastPathComponent.uppercased()
        
        if filename.contains("AIM") || filename.contains("PECHO") {
            return .aimbot
        } else if filename.contains("HOLOGRAMA") || filename.contains("ARMA") || filename.contains("WEAPON") || 
                  filename.contains("PERSONAJE") || filename.contains("CHARACTER") || filename.contains("SKIN") {
            return .holograma
        }
        
        // Default to others for unrecognized patches
        return .others
    }
    
    var info: String? {
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
