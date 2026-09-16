import SwiftUI

struct FreeFireView: View {
    enum GameMode: String, CaseIterable, Identifiable {
        case normal = "Free Fire"
        case max = "Free Fire MAX"
        
        var id: String { rawValue }
        
        var targetBundleID: String {
            switch self {
            case .normal: return "com.dts.freefireth"
            case .max: return "com.dts.freefiremax"
            }
        }
        
        var assetImageName: String {
            switch self {
            case .normal: return "freefire-icon"
            case .max: return "freefire-max-icon"
            }
        }
        
        var badgeText: String {
            switch self {
            case .normal: return "NORMAL"
            case .max: return "MAX"
            }
        }
        
        var badgeGradient: [Color] {
            switch self {
            case .normal: return [Color(hex: "8B5CF6"), Color(hex: "6366F1")]
            case .max: return [Color(hex: "EC4899"), Color(hex: "8B5CF6")]
            }
        }
    }
    
    let mode: GameMode
    
    init(mode: GameMode = .normal) {
        self.mode = mode
    }
    
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var patchStore: PatchProjectStore
    @StateObject private var keyStore = KeyStore.shared
    @StateObject private var announcementService = AnnouncementService.shared
    
    @State private var bundlePatches: [BundlePatch] = []
    @State private var selectedCategory: PatchCategory = .aimbot
    @State private var selectedHologramaSubcategory: HologramaSubcategory = .arma
    @State private var processingPatchIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showAnnouncementsSheet = false
    
    enum PatchCategory: String, CaseIterable, Identifiable {
        case aimbot = "AIMBOT"
        case holograma = "HOLOGRAMA"
        case others = "OTROS"
        
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
        NavigationStack {
            ZStack {
                Color(hex: "08080C").ignoresSafeArea()
                
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
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "08080C"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAnnouncementsSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "megaphone.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Anuncios")
                                .font(.system(size: 12, weight: .bold))
                            if announcementService.hasUnreadAnnouncements {
                                Circle()
                                    .fill(Color(hex: "EF4444"))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppTheme.accent.opacity(0.25))
                        )
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showAnnouncementsSheet) {
            AnnouncementModalView()
        }
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
            // Real-time Announcement / Game Header Banner
            headerHeroBanner
            
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
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Header Hero Banner
    
    private var headerHeroBanner: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Game logo
                Group {
                    if let uiImg = UIImage(named: mode.assetImageName) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 6)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(mode.rawValue)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text(mode.badgeText)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: mode.badgeGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: "10B981"))
                                .frame(width: 6, height: 6)
                            Text("Bypass Activo")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "10B981"))
                        }
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: "64748B"))
                        
                        Text("120 FPS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                
                Spacer()
                
                // Real-time "Ver Anuncio" Button
                Button {
                    showAnnouncementsSheet = true
                } label: {
                    VStack(spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Ver Anuncio")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        
                        Text("Tiempo Real")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "171827"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Latest Announcement Marquee / Sub-banner
            if let latest = announcementService.latestAnnouncement {
                Button {
                    showAnnouncementsSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Text(latest.tag)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.accent.opacity(0.18))
                            .clipShape(Capsule())
                        
                        Text(latest.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "E2E8F0"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "64748B"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "11121B"))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "0C0D14"))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        HStack(spacing: 8) {
            ForEach(PatchCategory.allCases) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(category.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selectedCategory == category ? .white : Color(hex: "94A3B8"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(selectedCategory == category ? AppTheme.accent : Color(hex: "131420"))
                    )
                    .overlay(
                        Capsule()
                            .stroke(selectedCategory == category ? AppTheme.accent.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: selectedCategory == category ? AppTheme.accent.opacity(0.3) : Color.clear, radius: 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "08080C"))
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
                            .lineLimit(1)
                    }
                    .foregroundStyle(selectedHologramaSubcategory == subcategory ? .white : Color(hex: "94A3B8"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedHologramaSubcategory == subcategory ? Color(hex: "1E2033") : Color(hex: "11121A"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedHologramaSubcategory == subcategory ? AppTheme.accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
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
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 76, height: 76)
                
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.accent.opacity(0.8))
            }
            .padding(.top, 36)
            
            VStack(spacing: 6) {
                Text("Categoría Vacía")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("No hay parches precargados en esta sección para \(mode.rawValue).\nPuedes importar tus proyectos .3105 o solicitarlos al soporte oficial.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "94A3B8"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)
            }
            
            Button {
                showAnnouncementsSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 12))
                    Text("Ver Anuncios y Novedades")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(AppTheme.accent)
                )
                .shadow(color: AppTheme.accent.opacity(0.4), radius: 6)
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 16)
        .obsidianCard(cornerRadius: 18, borderColor: Color.white.opacity(0.06))
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
                
                if !fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.copyItem(at: patch.url, to: destinationURL)
                }
                
                await MainActor.run {
                    patchStore.reload()
                }
                
                let items = await MainActor.run { patchStore.items }
                guard let item = items.first(where: {
                    $0.packageURL.lastPathComponent == patch.url.lastPathComponent
                }), let project = item.project else {
                    throw NSError(domain: "FreeFire", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "No se encontró el proyecto para \(patch.displayName)"
                    ])
                }
                
                if activate {
                    _ = try DevicePatchService.apply(project: project)
                    await MainActor.run {
                        patchStore.reload()
                        SoundPlayer.shared.playActivate()
                        processingPatchIDs.remove(patch.id)
                    }
                } else {
                    if let receipt = DevicePatchService.latestReceipt(projectID: project.id) {
                        try DevicePatchService.restore(receipt: receipt)
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
                        .fill(Color(hex: "EF4444").opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .stroke(Color(hex: "EF4444").opacity(0.4), lineWidth: 2)
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(Color(hex: "EF4444"))
                }
                .padding(.top, 10)
                
                VStack(spacing: 8) {
                    Text("ACCESO BANEADO")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: "EF4444"))
                    
                    Text("Tu clave de acceso ha sido inhabilitada por la administración.")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "94A3B8"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "shield.slash.fill")
                            .foregroundStyle(Color(hex: "EF4444"))
                        Text("ESTADO DE LA SANCIÓN")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: "94A3B8"))
                        Spacer()
                        Text("SUSPENDIDO")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "EF4444").opacity(0.2))
                            .foregroundStyle(Color(hex: "EF4444"))
                            .clipShape(Capsule())
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    if let keyString = keyStore.activeSession?.key.keyString {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Clave afectada:")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "94A3B8"))
                            Text(keyString)
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Motivo del bloqueo:")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: "94A3B8"))
                        Text(keyStore.banReason ?? "Violación de términos del servicio o uso no autorizado.")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(hex: "EF4444"))
                    }
                }
                .padding(16)
                .obsidianCard(cornerRadius: 18, borderColor: Color(hex: "EF4444").opacity(0.3))
                .padding(.horizontal, 24)
                
                VStack(spacing: 12) {
                    Text("Comunícate con soporte para apelar tu clave:")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "94A3B8"))
                    
                    Link(destination: URL(string: "https://wa.me/18099289722?text=Hola,%20mi%20clave%20de%20Project%20X%20fue%20baneada:\(keyStore.activeSession?.key.keyString ?? "")")!) {
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
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "10B981"))
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
                        .foregroundStyle(Color(hex: "94A3B8"))
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "08080C"))
    }
    
    // MARK: - Locked View
    
    private var lockedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 84, height: 84)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(AppTheme.accent)
            }
            
            VStack(spacing: 6) {
                Text("\(mode.rawValue) Bloqueado")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Activa tu clave de acceso desde la pestaña Perfil para habilitar el motor de inyección.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "94A3B8"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.accent)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("¿Cómo activar?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Dirígete a Perfil e ingresa tu clave asignada")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                    }
                    
                    Spacer()
                }
                .padding(16)
                .obsidianCard(cornerRadius: 14, borderColor: AppTheme.accent.opacity(0.25))
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "08080C"))
    }
}

// MARK: - Patch Toggle Row

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
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.accent.opacity(isActive ? 0.2 : 0.08))
                    .frame(width: 36, height: 36)
                Image(systemName: patch.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isActive ? AppTheme.accent : .white)
            }
            
            Text(patch.displayName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer()
            
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
                .tint(AppTheme.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .obsidianCard(cornerRadius: 16, borderColor: isActive ? AppTheme.accent.opacity(0.4) : AppTheme.cardBorder, glowing: isActive)
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
