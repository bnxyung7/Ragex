import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @StateObject private var adminSettings = AdminSettings.shared
    @StateObject private var keyStore = KeyStore.shared
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false

    @State private var selectedTab: Int = 0
    @State private var showSettings = false
    @State private var showLogs = false
    @State private var showWelcome = false
    @State private var filesSession = FilesTabSession()

    // MARK: - Init (simulator flags)

    init() {
#if targetEnvironment(simulator)
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--simulate-files-tab") {
            _selectedTab = State(initialValue: AppSection.files.rawValue)
        } else if args.contains("--simulate-patch-tab") {
            _selectedTab = State(initialValue: AppSection.patches.rawValue)
        }
#endif
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }

            // Global in-app toast overlay — always on top
            InAppToastOverlay()
        }
        .tint(AppTheme.accent)
        // Reconcile tab when key/admin settings change
        .onChange(of: developerModeEnabled) { _ in reconcile() }
        .onChange(of: adminSettings.tabSettings) { _ in reconcile() }
        .onChange(of: keyStore.activeSession?.key.status) { _ in reconcile() }
        .onAppear {
            reconcile()
            SoundPlayer.shared.playWelcome()
            if !OnboardingStore.shouldShow(), !UserDefaults.standard.bool(forKey: "hasSeenWelcome") {
                showWelcome = true
                UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
            }
            // Hide the native UITabBar completely — we use our own
            UITabBar.appearance().isHidden = true
            
            // Listen for quick access navigation
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NavigateToTab"),
                object: nil,
                queue: .main
            ) { notification in
                if let tabValue = notification.userInfo?["tab"] as? Int {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = tabValue
                    }
                }
            }
        }
        // Patch coordinator deep-links
        .onChange(of: patchDraftCoordinator.request?.id) { id in
            if id != nil { selectedTab = AppSection.patches.rawValue }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { id in
            if id != nil { selectedTab = AppSection.patches.rawValue }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs)     { LogView()      }
        .sheet(isPresented: $showWelcome)  { WelcomeSheet() }
        .patchStorePresentation(patchStore)
        .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
    }

    // MARK: - Compact layout (iPhone)

    private var compactLayout: some View {
        CustomTabBarContainer(
            selectedTab: $selectedTab,
            items: tabItems
        ) { section in
            AnyView(sectionContent(section))
        }
    }

    // MARK: - Regular layout (iPad sidebar)

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(visibleSections) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedTab = section.rawValue
                        }
                    } label: {
                        HStack(spacing: 12) {
                            sidebarIcon(for: section)
                            Text(sectionTitle(section))
                                .fontWeight(section.rawValue == selectedTab ? .semibold : .regular)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        section.rawValue == selectedTab
                            ? AppTheme.accent.opacity(0.14)
                            : Color.clear
                    )
                    .accessibilityAddTraits(
                        section.rawValue == selectedTab ? .isSelected : []
                    )
                }
            }
            .navigationTitle("X")
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            sectionContent(selectedVisibleSection)
                .id(selectedVisibleSection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Sidebar icon (iPad)

    @ViewBuilder
    private func sidebarIcon(for section: AppSection) -> some View {
        if let assetName = assetImageName(for: section),
           let img = UIImage(named: assetName) {
            Image(uiImage: img)
                .renderingMode(.original)
                .interpolation(.high)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Image(systemName: section.systemImage)
                .font(.system(size: 16))
                .foregroundStyle(section.rawValue == selectedTab ? AppTheme.accent : .secondary)
        }
    }

    // MARK: - Section content

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            RepositoryHomeView(onOpenSettings: { showSettings = true },
                               onOpenLogs:     { showLogs     = true })
        case .files:
            AppDataBrowserView(
                tabSession:     filesTabSession,
                onOpenSettings: { showSettings = true },
                onOpenLogs:     { showLogs     = true }
            )
        case .patches:
            PatchProjectsView(onOpenSettings: { showSettings = true },
                              onOpenLogs:     { showLogs     = true })
        case .freeFire:
            FreeFireView(mode: .normal)
        case .profile:
            ProfileView()
        case .support:
            SupportView()
        case .bundleExplorer:
            BundleExplorerView()
        }
    }

    // MARK: - Tab items for CustomTabBar

    private var tabItems: [TabBarItemModel] {
        visibleSections.map { section in
            TabBarItemModel(
                id:          section.rawValue,
                section:     section,
                title:       sectionTitle(section),
                systemImage: section.systemImage,
                assetImage:  assetImageName(for: section)
            )
        }
    }

    // MARK: - Helpers

    private var featureVisibility: FeatureVisibility {
        FeatureVisibility(
            developerModeEnabled: developerModeActive,
            adminSettings: adminSettings
        )
    }

    private var visibleSections: [AppSection] {
        featureVisibility.visibleSections
    }

    private var developerModeActive: Bool {
#if targetEnvironment(simulator)
        developerModeEnabled
            || ProcessInfo.processInfo.arguments.contains("--simulate-developer-mode")
            || ProcessInfo.processInfo.arguments.contains("--simulate-files-tab")
#else
        developerModeEnabled
#endif
    }

    private var selectedVisibleSection: AppSection {
        let selected = AppSection(rawValue: selectedTab)
        return selected.flatMap {
            featureVisibility.isVisible($0) ? $0 : nil
        } ?? .home
    }

    private var filesTabSession: Binding<FilesTabSession> {
        Binding(
            get: { filesSession },
            set: { filesSession = $0 }
        )
    }

    private func reconcile() {
        let visibility = featureVisibility
        if let current = AppSection(rawValue: selectedTab),
           !visibility.isVisible(current) {
            // Evitar ciclo: solo cambiar si no está ya en home
            guard selectedTab != AppSection.home.rawValue else { return }
            selectedTab = AppSection.home.rawValue
        }
    }

    private func assetImageName(for section: AppSection) -> String? {
        switch section {
        case .freeFire: return "freefire-icon"
        default:        return nil
        }
    }

    private func sectionTitle(_ section: AppSection) -> String {
        switch section {
        case .home:          return language.text("tab.home")
        case .files:         return language.text("tab.files")
        case .patches:       return language.text("tab.patches")
        case .freeFire:      return "Free Fire"
        case .profile:       return "Perfil"
        case .support:       return "Soporte"
        case .bundleExplorer:return "Bundle"
        }
    }
}

// MARK: - AppSection system image extension

private extension AppSection {
    var systemImage: String {
        switch self {
        case .home:          return "house.fill"
        case .files:         return "folder.fill"
        case .patches:       return "shippingbox.fill"
        case .freeFire:      return "flame.fill"
        case .profile:       return "person.fill"
        case .support:       return "headphones.circle.fill"
        case .bundleExplorer:return "folder.badge.gearshape"
        }
    }
}
