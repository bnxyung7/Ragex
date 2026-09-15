import SwiftUI

struct FreeFireView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var patchStore: PatchProjectStore
    @StateObject private var keyStore = KeyStore.shared
    @State private var bundlePatches: [BundlePatch] = []
    @State private var selectedCategory: PatchCategory = .aimbot
    @State private var selectedHologramaSubcategory: HologramaSubcategory = .arma
    @State private var processingPatchIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
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
    
    enum HologramaSubcategory: String, CaseIterable, Identifiable {
        case arma = "Arma"
        case personaje = "Personaje"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .arma: return "scope"
            case .personaje: return "person.fill"
            }
        }
        
        var displayName: String {
            switch self {
            case .arma: return "Holograma Arma"
            case .personaje: return "Holograma Personaje"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Group {
                    if keyStore.isBanned {
                        bannedView
                    } else if keyStore.hasValidAccess() {
                        mainContentView
                    } else {
                        lockedView
                    }
                }
            }
            .navigationTitle("Free Fire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Ocurrió un error inesperado.")
        }
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            categoryPicker
            
            ScrollView {
                VStack(spacing: 12) {
                    if selectedCategory == .holograma {
                        hologramaSubcategoryPicker
                        hologramaPatchList
                    } else if filteredPatches.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredPatches) { patch in
                            PatchToggleRow(
                                patch: patch,
                                isProcessing: processingPatchIDs.contains(patch.id),
                                onToggle: { activate in
                                    togglePatch(patch, activate: activate)
                                }
                            )
                            .environmentObject(patchStore)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        HStack(spacing: 10) {
            ForEach(PatchCategory.allCases) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(category.rawValue)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(selectedCategory == category ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(selectedCategory == category ? Color.white : Color(red: 0.14, green: 0.14, blue: 0.16))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black)
    }
    
    // MARK: - Holograma Subcategory Picker
    
    private var hologramaSubcategoryPicker: some View {
        HStack(spacing: 10) {
            ForEach(HologramaSubcategory.allCases) { subcategory in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedHologramaSubcategory = subcategory
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: subcategory.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(subcategory.displayName)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(selectedHologramaSubcategory == subcategory ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedHologramaSubcategory == subcategory ? Color(red: 0.22, green: 0.22, blue: 0.25) : Color(red: 0.11, green: 0.11, blue: 0.13))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedHologramaSubcategory == subcategory ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 6)
    }
    
    // MARK: - Holograma Patch List
    
    private var hologramaPatches: [BundlePatch] {
        bundlePatches.filter { patch in
            patch.category == .holograma && patch.subcategory == selectedHologramaSubcategory.rawValue
        }
    }
    
    @ViewBuilder
    private var hologramaPatchList: some View {
        if hologramaPatches.isEmpty {
            emptyState
        } else {
            ForEach(hologramaPatches) { patch in
                PatchToggleRow(
                    patch: patch,
                    isProcessing: processingPatchIDs.contains(patch.id),
                    onToggle: { activate in
                        togglePatch(patch, activate: activate)
                    }
                )
                .environmentObject(patchStore)
            }
        }
    }
    
    private var filteredPatches: [BundlePatch] {
        bundlePatches.filter { $0.category == selectedCategory }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundStyle(.gray.opacity(0.5))
                .padding(.top, 40)
            
            Text("No hay parches disponibles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            
            Text("No se encontraron archivos .3105 en esta categoría")
                .font(.system(size: 13))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Toggle Patch Action
    
    private func togglePatch(_ patch: BundlePatch, activate: Bool) {
        guard !processingPatchIDs.contains(patch.id) else { return }
        processingPatchIDs.insert(patch.id)
        
        Task.detached(priority: .userInitiated) {
            do {
                let fileManager = FileManager.default
                guard let destinationRoot = try? PatchProjectLibrary.packageRootURL(
                    fileManager: fileManager
                ) else {
                    throw NSError(domain: "FreeFire", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "No se pudo acceder a la librería de parches"
                    ])
                }
                
                let destinationURL = destinationRoot.appendingPathComponent(patch.url.lastPathComponent)
                
                // Copy if doesn't exist
                if !fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.copyItem(at: patch.url, to: destinationURL)
                }
                
                // Reload store to recognize file
                await MainActor.run {
                    patchStore.reload()
                }
                
                // Find item & project
                let items = await MainActor.run { patchStore.items }
                guard let item = items.first(where: {
                    $0.packageURL.lastPathComponent == patch.url.lastPathComponent
                }), let project = item.project else {
                    throw NSError(domain: "FreeFire", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "No se encontró el proyecto para \(patch.displayName)"
                    ])
                }
                
                if activate {
                    // Apply patch
                    _ = try DevicePatchService.apply(project: project)
                    await MainActor.run {
                        patchStore.reload()
                        SoundPlayer.shared.playActivate()
                        processingPatchIDs.remove(patch.id)
                    }
                } else {
                    // Deactivate patch
                    if let receipt = DevicePatchService.latestReceipt(projectID: project.id) {
                        _ = try DevicePatchService.restore(
                            receipt: receipt,
                            store: patchStore,
                            project: project
                        )
                    }
                    await MainActor.run {
                        patchStore.reload()
                        SoundPlayer.shared.playDeactivate()
                        processingPatchIDs.remove(patch.id)
                    }
                }
            } catch {
                await MainActor.run {
                    processingPatchIDs.remove(patch.id)
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
                print("[FreeFire] Toggle error: \(error)")
            }
        }
    }
    
    // MARK: - Load Bundle Patches
    
    private func loadBundlePatches() {
        let fileManager = FileManager.default
        
        guard let bundleURL = Bundle.main.resourceURL else { return }
        
        var patches: [BundlePatch] = []
        var seenFilenames = Set<String>()
        
        let preinstalledFolder = bundleURL.appendingPathComponent("PreinstalledPatches", isDirectory: true)
        if fileManager.fileExists(atPath: preinstalledFolder.path) {
            if let enumerator = fileManager.enumerator(at: preinstalledFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "3105" {
                        let filename = fileURL.lastPathComponent
                        if !seenFilenames.contains(filename) {
                            seenFilenames.insert(filename)
                            patches.append(BundlePatch(url: fileURL))
                        }
                    }
                }
            }
        }
        
        bundlePatches = patches
    }
    
    // MARK: - Banned View
    
    private var bannedView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .stroke(Color.red.opacity(0.4), lineWidth: 2)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(.red)
                }
                .padding(.top, 10)
                
                VStack(spacing: 8) {
                    Text("ACCESO BANEADO")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.red)
                    
                    Text("Tu clave de Free Fire ha sido inhabilitada por la administración.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "shield.slash.fill")
                            .foregroundStyle(.red)
                        Text("ESTADO DE LA SANCIÓN")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("SUSPENDIDO")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.2))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                    
                    Divider()
                    
                    if let keyString = keyStore.activeSession?.key.keyString {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Clave afectada:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(keyString)
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Motivo del bloqueo:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(keyStore.banReason ?? "Violación de términos del servicio o uso no autorizado.")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                
                VStack(spacing: 12) {
                    Text("Comunícate con soporte para apelar tu clave:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Link(destination: URL(string: "https://wa.me/18099289722?text=Hola,%20mi%20clave%20de%20Free%20Fire%20fue%20baneada:\(keyStore.activeSession?.key.keyString ?? "")")!) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Soporte Oficial WhatsApp")
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                    }
                    
                    Button(role: .destructive) {
                        keyStore.deactivateSession()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Cerrar Sesión")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Locked View
    
    private var lockedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
            
            Text("Free Fire Bloqueado")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("Free Fire está bloqueado. Activa tu Key desde Perfil.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("¿Cómo activar?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text("Ve a la pestaña Perfil e introduce tu Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Patch Toggle Row (New Design matching screenshot)

struct PatchToggleRow: View {
    let patch: BundlePatch
    let isProcessing: Bool
    let onToggle: (Bool) -> Void
    @EnvironmentObject private var patchStore: PatchProjectStore
    
    private var patchProject: PatchProject? {
        let items = patchStore.items
        guard let item = items.first(where: {
            $0.packageURL.lastPathComponent == patch.url.lastPathComponent
        }) else { return nil }
        return item.project
    }
    
    private var isActive: Bool {
        guard let project = patchProject else { return false }
        return DevicePatchService.latestReceipt(projectID: project.id) != nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Crosshair / Scope Icon
            Image(systemName: patch.icon)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22, alignment: .center)
            
            // Patch name
            Text(patch.displayName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Spacer()
            
            // Toggle Switch / Spinner
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.85)
                    .frame(width: 51, height: 31)
            } else {
                Toggle("", isOn: Binding(
                    get: { isActive },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(Color.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isProcessing {
                onToggle(!isActive)
            }
        }
    }
}

// MARK: - Bundle Patch Model

struct BundlePatch: Identifiable {
    let id = UUID()
    let url: URL
    
    var displayName: String {
        let filename = url.deletingPathExtension().lastPathComponent
        var name = filename.replacingOccurrences(of: "_", with: " ")
        name = name.replacingOccurrences(of: " PERCENT", with: "%")
        
        let components = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let cleanWords = components.map { word -> String in
            let upper = word.uppercased()
            if upper == "AIM" || upper == "ESP" || upper == "FPS" || upper.contains("%") {
                return upper
            } else if upper == "PJ" {
                return "Personaje"
            }
            return word.capitalized
        }
        return cleanWords.joined(separator: " ")
    }
    
    var icon: String {
        let name = url.lastPathComponent.uppercased()
        if name.contains("AIM") || name.contains("PECHO") || name.contains("CABEZA") || name.contains("CUELLO") || name.contains("NECK") {
            return "scope"
        } else if name.contains("HOLOGRAMA") {
            return "cube.transparent"
        } else if name.contains("PARED") || name.contains("WALL") || name.contains("GLOO") {
            return "shield.fill"
        } else if name.contains("BALA") {
            return "bolt.fill"
        } else if name.contains("ESP") || name.contains("LINEA") {
            return "eye.fill"
        } else if name.contains("PJ") || name.contains("PERSONAJE") {
            return "person.fill"
        } else if name.contains("ARMA") {
            return "scope"
        } else if name.contains("FPS") {
            return "speedometer"
        }
        return "scope"
    }
    
    var category: FreeFireView.PatchCategory {
        let filename = url.lastPathComponent.uppercased()
        let folderName = url.deletingLastPathComponent().lastPathComponent.uppercased()
        
        if folderName == "AIMBOT" || filename.contains("AIM") || filename.contains("PECHO") {
            return .aimbot
        } else if folderName == "HOLOGRAMA" || folderName == "ARMA" || folderName == "PERSONAJE" ||
                  filename.contains("HOLOGRAMA") || filename.contains("ARMA") ||
                  filename.contains("WEAPON") || filename.contains("PERSONAJE") ||
                  filename.contains("CHARACTER") || filename.contains("SKIN") {
            return .holograma
        }
        
        return .others
    }
    
    var subcategory: String? {
        if category == .holograma {
            let folderName = url.deletingLastPathComponent().lastPathComponent
            if folderName.lowercased() == "arma" {
                return "Arma"
            } else if folderName.lowercased() == "personaje" {
                return "Personaje"
            }
        }
        return nil
    }
    
    var info: String? {
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
