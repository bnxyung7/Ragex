import SwiftUI

struct FreeFireView: View {
    enum GameMode: String, CaseIterable, Identifiable {
        case normal = "Free Fire"

        var id: String { rawValue }

        var targetBundleID: String {
            return "com.dts.freefireth"
        }

        var assetImageName: String {
            return "freefire-icon"
        }

        var badgeText: String {
            return "NORMAL"
        }

        var badgeGradient: [Color] {
            return [Color(hex: "8B5CF6"), Color(hex: "6366F1")]
        }
    }

    let mode: GameMode

    init(mode: GameMode = .normal) {
        self.mode = mode
    }
    
    @Environment(\.appLanguage) private var language
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var patchStore: PatchProjectStore
    @StateObject private var keyStore = KeyStore.shared
    @StateObject private var announcementService = AnnouncementService.shared
    @StateObject private var productTagService = ProductTagService.shared
    @ObservedObject private var activationStore = PatchActivationStore.shared
    
    @State private var bundlePatches: [BundlePatch] = []
    @State private var selectedCategory: PatchCategory = .aimbot
    @State private var selectedHologramaSubcategory: HologramaSubcategory = .arma
    @State private var processingPatchIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showAnnouncementsSheet = false
    // Auto-refresh state
    @State private var lastRefreshed: Date = Date()
    @State private var isRefreshing: Bool = false
    @State private var didRestoreActivations = false
    private let refreshInterval: TimeInterval = 30
    
    enum PatchCategory: String, CaseIterable, Identifiable {
        case aimbot = "AIMBOT"
        case holograma = "HOLOGRAMA"
        case modSkin = "MOD SKIN"
        case combo = "COMBO"
        case others = "OTROS"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .aimbot: return "scope"
            case .holograma: return "cube.transparent"
            case .modSkin: return "paintbrush.fill"
            case .combo: return "star.fill"
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
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    announcementsToolbarButton
                }
            }
        }
        .sheet(isPresented: $showAnnouncementsSheet) {
            AnnouncementModalView()
        }
        .onAppear {
            loadBundlePatches()
            restoreSavedActivationsIfNeeded()
            // Refresh announcements immediately when tab opens
            Task { 
                await announcementService.fetchAnnouncements()
                await productTagService.fetchTags()
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                didRestoreActivations = false
            } else if phase == .active {
                restoreSavedActivationsIfNeeded()
            }
        }
        .onDisappear {
            // Nothing to tear down — timer is task-based and cancels with view
        }
        // Auto-refresh every 30s while the view is on screen
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval) * 1_000_000_000)
                guard !Task.isCancelled else { break }
                await performRefresh()
            }
        }
        .alert(language.text("ff.error"), isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? language.text("ff.unexpected"))
        }
    }
    
    // MARK: - Announcements Toolbar Button
    
    private var announcementsToolbarButton: some View {
        Button {
            showAnnouncementsSheet = true
        } label: {
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(language.text("ff.announcements"))
                    .font(.system(size: 12, weight: .bold))
                if announcementService.hasUnreadAnnouncements {
                    Circle()
                        .fill(Color(hex: "EF4444"))
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.spacing10)
            .padding(.vertical, AppTheme.spacing6)
            .background(AppTheme.accent.opacity(0.22))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            headerHeroBanner
            categoryPicker
            
            ScrollView {
                VStack(spacing: AppTheme.itemSpacing) {
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
                            .environmentObject(productTagService)
                        }
                    }
                    activationHistorySection
                }
                .padding(.horizontal, AppTheme.pageInset)
                .padding(.top, AppTheme.itemSpacing)
                .padding(.bottom, AppTheme.spacing32)
            }
        }
    }
    
    // MARK: - Header Hero Banner
    
    private var headerHeroBanner: some View {
        VStack(spacing: 0) {
            // Fila principal: Logo + Info + Botón
            HStack(alignment: .center, spacing: AppTheme.spacing12) {
                gameLogoView
                
                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    // Título con badge
                    HStack(spacing: AppTheme.spacing6) {
                        Text(mode.rawValue)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        Text(mode.badgeText)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: mode.badgeGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    
                    // Status line con separadores
                    HStack(spacing: 6) {
                        HStack(spacing: AppTheme.spacing4) {
                            PulseStatusDot(color: Color(hex: "10B981"))
                            Text(language.text("ff.active"))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "10B981"))
                        }

                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(hex: "64748B"))

                        Text("120 FPS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.accent)

                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(hex: "64748B"))

                        Button {
                            Task { await performRefresh() }
                        } label: {
                            HStack(spacing: 3) {
                                if isRefreshing {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.5)
                                        .tint(AppTheme.accent)
                                        .frame(width: 8, height: 8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(AppTheme.accent)
                                }
                                Text(language.text("ff.live"))
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AppTheme.accent.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(isRefreshing)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.pageInset)
            .padding(.vertical, AppTheme.spacing12)
            
            // Banner de anuncios (si existe)
            if let latest = announcementService.latestAnnouncement {
                marqueeBanner(latest)
                    .padding(.horizontal, AppTheme.pageInset)
                    .padding(.bottom, AppTheme.spacing10)
            }
        }
        .background(Color(hex: "0C0D14"))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private var gameLogoView: some View {
        if let uiImg = UIImage(named: mode.assetImageName) {
            Image(uiImage: uiImg)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 6)
        } else {
            Image(systemName: "flame.fill")
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AppTheme.accent.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private func marqueeBanner(_ latest: LiveAnnouncement) -> some View {
        Button {
            showAnnouncementsSheet = true
        } label: {
            HStack(spacing: AppTheme.spacing8) {
                Text(latest.tag)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white)
                    .clipShape(Capsule())
                
                Text(latest.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Spacer(minLength: 4)
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing10)
            .background(Color(hex: "101014"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacing8) {
                ForEach(PatchCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: AppTheme.spacing6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(category.rawValue)
                                .font(.system(size: 13, weight: .bold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(selectedCategory == category ? .white : Color(hex: "71717A"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? Color(hex: "222228") : Color(hex: "0D0D12"))
                        )
                        .overlay(
                            Capsule()
                                .stroke(selectedCategory == category ? Color.white.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .shadow(color: selectedCategory == category ? Color.white.opacity(0.08) : Color.clear, radius: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.pageInset)
        }
        .padding(.vertical, AppTheme.spacing10)
        .background(Color.black)
    }
    
    // MARK: - Holograma Subcategory Picker
    
    private var hologramaSubcategoryPicker: some View {
        HStack(spacing: AppTheme.spacing10) {
            ForEach(HologramaSubcategory.allCases) { subcategory in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedHologramaSubcategory = subcategory
                    }
                } label: {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: subcategory.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(subcategory.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selectedHologramaSubcategory == subcategory ? .white : Color(hex: "71717A"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacing8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedHologramaSubcategory == subcategory ? Color(hex: "222228") : Color(hex: "0D0D12"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedHologramaSubcategory == subcategory ? Color.white.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, AppTheme.spacing6)
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
                .environmentObject(productTagService)
            }
        }
    }

    private var activationHistorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text(language.text("ff.history"))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "94A3B8"))
                .textCase(.uppercase)
                .tracking(0.6)

            if activationStore.history.isEmpty {
                Text(language.text("ff.history_empty"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "64748B"))
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(activationStore.history.prefix(8))) { event in
                    HStack(alignment: .center, spacing: 10) {
                        Circle()
                            .fill(event.activated ? Color(hex: "10B981") : Color(hex: "64748B"))
                            .frame(width: 7, height: 7)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.displayName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text("\(event.activated ? language.text("ff.activated") : language.text("ff.deactivated"))  ·  \(formattedHistoryDate(event.date))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color(hex: "94A3B8"))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(AppTheme.cardPadding)
        .obsidianCard(cornerRadius: 16, borderColor: Color.white.opacity(0.06))
    }

    private func formattedHistoryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var filteredPatches: [BundlePatch] {
        bundlePatches.filter { $0.category == selectedCategory }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.spacing16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 76, height: 76)
                
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.accent.opacity(0.8))
            }
            .padding(.top, 36)
            
            VStack(spacing: AppTheme.spacing8) {
                Text(language.text("ff.empty"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 16)
        .obsidianCard(cornerRadius: 18, borderColor: Color.white.opacity(0.06))
    }
    
    // MARK: - Toggle Patch Action
    
    private func togglePatch(_ patch: BundlePatch, activate: Bool, recordHistory: Bool = true) {
        guard !processingPatchIDs.contains(patch.id) else { return }
        processingPatchIDs.insert(patch.id)

        Task.detached(priority: .userInitiated) {
            // Timeout safety: always clear spinner after 15s max
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                processingPatchIDs.remove(patch.id)
            }
            do {
                let fileManager = FileManager.default
                guard let destinationRoot = try? PatchProjectLibrary.packageRootURL(
                    fileManager: fileManager
                ) else {
                    throw NSError(domain: "FreeFire", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "No se pudo acceder a la librería de parches"
                    ])
                }
                
                // Determine destination filename (always .3105, never .3105e)
                var destFilename = patch.url.lastPathComponent
                if patch.isEncrypted {
                    // Remove .3105e extension, add .3105
                    destFilename = patch.url.deletingPathExtension().lastPathComponent
                    if !destFilename.hasSuffix(".3105") {
                        destFilename += ".3105"
                    }
                    print("[FreeFire] 🔓 Encrypted file: \(patch.url.lastPathComponent) → \(destFilename)")
                }
                
                let destinationURL = destinationRoot.appendingPathComponent(destFilename)
                print("[FreeFire] 📍 Destination: \(destinationURL.path)")
                
                var fileNeedsWriting = !fileManager.fileExists(atPath: destinationURL.path)
                if !fileNeedsWriting {
                    let attr = try? fileManager.attributesOfItem(atPath: destinationURL.path)
                    let size = (attr?[.size] as? Int64) ?? 0
                    if size == 0 {
                        fileNeedsWriting = true
                        try? fileManager.removeItem(at: destinationURL)
                    }
                }

                if fileNeedsWriting {
                    // Handle encrypted files
                    if patch.isEncrypted {
                        let userKey = await MainActor.run {
                            KeyStore.shared.activeSession?.key.keyString
                                ?? KeyStore.shared.allKeys.first?.keyString
                                ?? "RagexMasterKey"
                        }
                        
                        let encryptionService = await MainActor.run { FileEncryptionService.shared }
                        do {
                            let decryptedData = try await encryptionService.decryptFile(at: patch.url, userKey: userKey)
                            try decryptedData.write(to: destinationURL)
                            print("[FreeFire] ✅ Decrypted and copied to: \(destinationURL.path) (\(decryptedData.count) bytes)")
                        } catch {
                            print("[FreeFire] ⚠️ Decryption failed (\(error.localizedDescription)), attempting raw copy fallback...")
                            try? fileManager.removeItem(at: destinationURL)
                            try fileManager.copyItem(at: patch.url, to: destinationURL)
                        }
                    } else {
                        // Copy plain file directly
                        try? fileManager.removeItem(at: destinationURL)
                        try fileManager.copyItem(at: patch.url, to: destinationURL)
                        print("[FreeFire] ✅ Copied: \(destFilename)")
                    }
                } else {
                    print("[FreeFire] ℹ️ File already exists: \(destFilename)")
                }
                
                await MainActor.run {
                    patchStore.reload()
                }
                
                let items = await MainActor.run { patchStore.items }
                var project = items.first(where: {
                    $0.packageURL.lastPathComponent == destFilename
                })?.project
                
                // Fallback: decode directly if store hasn't populated yet
                if project == nil, let pkgData = try? Data(contentsOf: destinationURL) {
                    if let decoded = try? PatchPackageCodec.decode(pkgData, password: nil) {
                        project = decoded.project
                    }
                }
                
                guard let resolvedProject = project else {
                    throw NSError(domain: "FreeFire", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "No se pudo preparar el proyecto para \(patch.displayName)"
                    ])
                }
                
                if activate {
                    _ = try DevicePatchService.apply(project: resolvedProject)
                    await MainActor.run {
                        PatchActivationStore.shared.record(patch: patch, activated: true, recordHistory: recordHistory)
                        patchStore.reload()
                        SoundPlayer.shared.playActivate()
                        processingPatchIDs.remove(patch.id)
                    }
                } else {
                    if let receipt = DevicePatchService.latestReceipt(projectID: resolvedProject.id) {
                        try DevicePatchService.restore(receipt: receipt)
                    }
                    await MainActor.run {
                        PatchActivationStore.shared.record(patch: patch, activated: false, recordHistory: recordHistory)
                        patchStore.reload()
                        SoundPlayer.shared.playDeactivate()
                        processingPatchIDs.remove(patch.id)
                    }
                }
            } catch {
                let errText = error.localizedDescription
                await MainActor.run {
                    errorMessage = errText
                    showErrorAlert = true
                    processingPatchIDs.remove(patch.id)
                    patchStore.reload()
                }
                log("freeFire: toggle error — \(errText)")
                
                // Report error to backend telemetry
                let currentKey = await MainActor.run { KeyStore.shared.activeSession?.key.keyString ?? KeyStore.shared.allKeys.first?.keyString }
                Task.detached {
                    await KeyAPIService.shared.reportExecutionError(
                        keyString: currentKey,
                        action: activate ? "apply_patch" : "restore_patch",
                        targetBundle: patch.displayName,
                        errorMessage: errText
                    )
                }
            }
        }
    }
    
    // MARK: - Auto-Refresh

    @MainActor
    private func performRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        // 1. Reload bundle patches from disk
        loadBundlePatches()

        // 2. Refresh patch store so toggle states are current
        patchStore.reload()

        // 3. Pull latest announcements from server
        await announcementService.fetchAnnouncements()

        lastRefreshed = Date()
        print("[FreeFireView:\(mode.rawValue)] 🔄 Auto-refreshed at \(lastRefreshed)")
    }

    // MARK: - Load Bundle Patches
    
    private func loadBundlePatches() {
        let fileManager = FileManager.default
        guard let bundleURL = Bundle.main.resourceURL else { return }
        
        var patches: [BundlePatch] = []
        var seenFilenames = Set<String>()
        
        // Determinar subcarpeta según modo
        let modeFolder = mode == .normal ? "FREE_FIRE" : "FREE_FIRE_MAX"
        let preinstalledFolder = bundleURL
            .appendingPathComponent("PreinstalledPatches", isDirectory: true)
            .appendingPathComponent(modeFolder, isDirectory: true)
        
        if fileManager.fileExists(atPath: preinstalledFolder.path) {
            if let enumerator = fileManager.enumerator(at: preinstalledFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    let ext = fileURL.pathExtension.lowercased()
                    
                    // Soportar archivos .3105 (legacy) y .3105e (encriptados)
                    if ext == "3105" || ext == "3105e" {
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
        syncActivationStoreFromReceipts()
        print("[FreeFireView:\(mode.rawValue)] Loaded \(patches.count) patches from \(modeFolder)")
        
        // Debug: Print all product IDs for tag matching
        for patch in patches where patch.category == .aimbot {
            print("[ProductTag Debug] \(patch.displayName) → productId: \(patch.productId)")
        }
    }

    private func destinationFilename(for patch: BundlePatch) -> String {
        var destFilename = patch.url.lastPathComponent
        if patch.isEncrypted {
            destFilename = patch.url.deletingPathExtension().lastPathComponent
            if !destFilename.hasSuffix(".3105") {
                destFilename += ".3105"
            }
        }
        return destFilename
    }

    private func project(for patch: BundlePatch) -> PatchProject? {
        let destFilename = destinationFilename(for: patch)
        return patchStore.items.first(where: {
            $0.packageURL.lastPathComponent == destFilename
        })?.project
    }

    private func syncActivationStoreFromReceipts() {
        for patch in bundlePatches {
            guard let project = project(for: patch),
                  DevicePatchService.latestReceipt(projectID: project.id) != nil else { continue }
            if !activationStore.isActive(patch) {
                activationStore.record(patch: patch, activated: true, recordHistory: false)
            }
        }
    }

    private func restoreSavedActivationsIfNeeded() {
        guard !didRestoreActivations else { return }
        didRestoreActivations = true
        for patch in bundlePatches where activationStore.isActive(patch) {
            if let project = project(for: patch),
               DevicePatchService.latestReceipt(projectID: project.id) != nil {
                continue
            }
            togglePatch(patch, activate: true, recordHistory: false)
        }
    }
    
    // MARK: - Banned View
    
    private var bannedView: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing24) {
                Spacer(minLength: AppTheme.spacing20)
                
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
                .padding(.top, AppTheme.spacing10)
                
                VStack(spacing: AppTheme.spacing10) {
                    Text(language.text("ff.banned_title"))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: "EF4444"))
                    
                    Text(language.text("ff.banned_body"))
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "94A3B8"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.spacing24)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.spacing14) {
                    HStack {
                        Image(systemName: "shield.slash.fill")
                            .foregroundStyle(Color(hex: "EF4444"))
                        Text(language.text("ff.ban_status"))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: "94A3B8"))
                        Spacer()
                        Text(language.text("ff.suspended"))
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "EF4444").opacity(0.2))
                            .foregroundStyle(Color(hex: "EF4444"))
                            .clipShape(Capsule())
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    if let keyString = keyStore.activeSession?.key.keyString {
                        VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                            Text(language.text("ff.affected_key"))
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "94A3B8"))
                            Text(keyString)
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                        Text(language.text("ff.ban_reason"))
                            .font(.caption2)
                            .foregroundStyle(Color(hex: "94A3B8"))
                        Text(keyStore.banReason ?? language.text("ff.ban_reason_default"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(AppTheme.cardPadding)
                .obsidianCard(cornerRadius: 18, borderColor: Color(hex: "EF4444").opacity(0.3))
                .padding(.horizontal, AppTheme.spacing24)
                
                VStack(spacing: AppTheme.itemSpacing) {
                    Text(language.text("ff.appeal"))
                        .font(.caption)
                        .foregroundStyle(Color(hex: "94A3B8"))
                    
                    Link(destination: URL(string: "https://wa.me/18099289722?text=Hola,%20mi%20clave%20de%20Project%20X%20fue%20baneada:\(keyStore.activeSession?.key.keyString ?? "")")!) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text(language.text("ff.whatsapp"))
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
                            Text(language.text("ff.logout"))
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
        VStack(spacing: AppTheme.spacing24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 84, height: 84)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(AppTheme.accent)
            }
            
            VStack(spacing: AppTheme.spacing8) {
                Text(language.text("ff.locked_title", mode.rawValue))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(language.text("ff.locked_body"))
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "94A3B8"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.spacing32)
            }
            
            VStack(spacing: AppTheme.itemSpacing) {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.accent)
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                        Text(language.text("ff.how_activate"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(language.text("ff.how_activate_body"))
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.cardPadding)
                .obsidianCard(cornerRadius: 14, borderColor: AppTheme.accent.opacity(0.25))
            }
            .padding(.horizontal, AppTheme.spacing24)
            
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
    @EnvironmentObject private var productTagService: ProductTagService
    @ObservedObject private var activationStore = PatchActivationStore.shared
    
    private var patchProject: PatchProject? {
        let items = patchStore.items
        
        // Get the actual filename that was copied to the package directory
        // For encrypted files (.3105e), we need to search for the .3105 version
        var searchFilename = patch.url.lastPathComponent
        if patch.isEncrypted {
            // Convert .3105e → .3105
            searchFilename = patch.url.deletingPathExtension().lastPathComponent
            if !searchFilename.hasSuffix(".3105") {
                searchFilename += ".3105"
            }
        }
        
        guard let item = items.first(where: {
            $0.packageURL.lastPathComponent == searchFilename
        }) else { return nil }
        return item.project
    }
    
    private var isActive: Bool {
        if activationStore.isActive(patch) { return true }
        guard let project = patchProject else { return false }
        return DevicePatchService.latestReceipt(projectID: project.id) != nil
    }
    
    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.accent.opacity(isActive ? 0.2 : 0.08))
                    .frame(width: 36, height: 36)
                Image(systemName: patch.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isActive ? AppTheme.accent : .white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(patch.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
                
                // Product Tag Badge
                if let tag = productTagService.getTag(for: patch.productId) {
                    Text(tag.tag.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(Color(hex: tag.hexColor))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: tag.hexColor).opacity(0.15))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: tag.hexColor).opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
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
        .padding(.horizontal, AppTheme.cardPadding)
        .padding(.vertical, 14)
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
    
    /// Check if this patch is encrypted (.3105e)
    var isEncrypted: Bool {
        return url.pathExtension.lowercased() == "3105e"
    }
    
    var displayName: String {
        // Remove .3105e extension if encrypted, show clean name
        var filename = url.deletingPathExtension().lastPathComponent
        
        // If still has .3105 (from .3105e), remove it
        if filename.hasSuffix(".3105") {
            filename = String(filename.dropLast(5))
        }
        
        var name = filename.replacingOccurrences(of: "_", with: " ")
        name = name.replacingOccurrences(of: " PERCENT", with: "%")
        
        // Convert everything to uppercase for better visibility
        return name.uppercased()
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
        
        // Prioridad 1: Verificar carpeta exacta (más confiable)
        if folderName == "AIMBOT" {
            return .aimbot
        } else if folderName == "HOLOGRAMA" || folderName == "ARMA" || folderName == "PERSONAJE" {
            return .holograma
        } else if folderName == "MOD_SKIN" || folderName == "TEXTURA" || folderName == "TEXTURE" {
            return .modSkin
        } else if folderName == "COMBO" {
            return .combo
        }
        
        // Prioridad 2: Si no está en carpeta específica, detectar por nombre de archivo
        if filename.contains("AIMBOT") || filename.contains("AIM") || filename.contains("PECHO") {
            return .aimbot
        } else if filename.contains("HOLOGRAMA") || filename.contains("ARMA") ||
                  filename.contains("WEAPON") || filename.contains("PERSONAJE") ||
                  filename.contains("CHARACTER") {
            return .holograma
        } else if filename.contains("TEXTURA") || filename.contains("TEXTURE") ||
                  filename.contains("SKIN") || filename.contains("MOD") {
            return .modSkin
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
    
    /// Generate product ID for tag lookup (format: GAME_CATEGORY_NAME)
    var productId: String {
        let game = "FREE_FIRE"
        let cat = category.rawValue
        
        // Get filename without extension
        var filename = url.deletingPathExtension().lastPathComponent
        
        // If encrypted (.3105e), remove the .3105 part too
        if isEncrypted && filename.hasSuffix(".3105") {
            filename = String(filename.dropLast(5))
        }
        
        let name = filename
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "%", with: "_PERCENT")
        return "\(game)_\(cat)_\(name)"
    }
}
