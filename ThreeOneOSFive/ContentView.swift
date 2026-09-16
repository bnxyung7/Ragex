import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @StateObject private var adminSettings = AdminSettings.shared
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false
    @State private var tabNavigation: AppTabNavigationState
    @State private var showSettings = false
    @State private var showLogs = false
    @State private var showWelcome = false

    init() {
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Int
        if arguments.contains("--simulate-files-tab") {
            initialTab = 1
        } else if arguments.contains("--simulate-patch-tab") {
            initialTab = 2
        } else {
            initialTab = 0
        }
        _tabNavigation = State(initialValue: AppTabNavigationState(selectedTab: initialTab))
        _showSettings = State(
            initialValue: arguments.contains("--simulate-settings")
        )
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
#endif
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .tint(AppTheme.accent)
        .imageScale(.small)
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
        }
        .onChange(of: developerModeEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onChange(of: adminSettings.tabSettings) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
            
            // Play welcome sound every time app opens
            SoundPlayer.shared.playWelcome()
            
            // Show welcome sheet on first launch only
            if !UserDefaults.standard.bool(forKey: "hasSeenWelcome") {
                showWelcome = true
                UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
        .sheet(isPresented: $showWelcome) { WelcomeSheet() }
        .patchStorePresentation(patchStore)
        .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
    }

    private var compactLayout: some View {
        TabView(selection: tabSelection) {
            ForEach(featureVisibility.visibleSections) { section in
                sectionContent(section)
                    .tabItem {
                        CompactTabLabel(
                            section: section,
                            title: sectionTitle(section)
                        )
                    }
                    .tag(section.rawValue)
            }
        }
        .toolbarBackground(Color(hex: "08080C"), for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(featureVisibility.visibleSections) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            tabNavigation.select(section.rawValue)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            sidebarIcon(for: section)
                            Text(sectionTitle(section))
                                .fontWeight(section.rawValue == tabNavigation.selectedTab ? .semibold : .regular)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        section.rawValue == tabNavigation.selectedTab
                            ? AppTheme.accent.opacity(0.14)
                            : Color.clear
                    )
                    .accessibilityAddTraits(
                        section.rawValue == tabNavigation.selectedTab ? .isSelected : []
                    )
                }
            }
            .navigationTitle("Project X")
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            sectionContent(selectedVisibleSection)
                .id(selectedVisibleSection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sidebarIcon(for section: AppSection) -> some View {
        if section == .freeFire, let img = UIImage(named: "freefire-icon") {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else if section == .freeFireMax, let img = UIImage(named: "freefire-max-icon") {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Image(systemName: section.systemImage)
                .font(.system(size: 16))
                .foregroundStyle(section.rawValue == tabNavigation.selectedTab ? AppTheme.accent : .secondary)
        }
    }

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            RepositoryHomeView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .files:
            AppDataBrowserView(
                tabSession: filesTabSession,
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .patches:
            PatchProjectsView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .freeFire:
            FreeFireView(mode: .normal)
        case .freeFireMax:
            FreeFireView(mode: .max)
        case .profile:
            ProfileView()
        case .support:
            SupportView()
        case .bundleExplorer:
            BundleExplorerView()
        }
    }

    private var tabSelection: Binding<Int> {
        Binding(
            get: { tabNavigation.selectedTab },
            set: { tabNavigation.select($0) }
        )
    }

    private var filesTabSession: Binding<FilesTabSession> {
        Binding(
            get: { tabNavigation.filesTabs },
            set: { tabNavigation.setFilesTabs($0) }
        )
    }

    private var featureVisibility: FeatureVisibility {
        FeatureVisibility(developerModeEnabled: developerModeActive, adminSettings: adminSettings)
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
        let selected = AppSection(rawValue: tabNavigation.selectedTab)
        return selected.flatMap {
            featureVisibility.isVisible($0) ? $0 : nil
        } ?? .home
    }

    private func sectionTitle(_ section: AppSection) -> String {
        switch section {
        case .home: return language.text("tab.home")
        case .files: return language.text("tab.files")
        case .patches: return language.text("tab.patches")
        case .freeFire: return "Free Fire"
        case .freeFireMax: return "FF MAX"
        case .profile: return "Perfil"
        case .support: return "Soporte"
        case .bundleExplorer: return "Bundle"
        }
    }

    private func openSettings() {
        showSettings = true
    }

    private func openLogs() {
        showLogs = true
    }
}

private struct CompactTabLabel: View {
    let section: AppSection
    let title: String

    @ViewBuilder
    var body: some View {
        if section == .freeFire, let img = UIImage(named: "freefire-icon") {
            Image(uiImage: img)
                .renderingMode(.original)
        } else if section == .freeFireMax, let img = UIImage(named: "freefire-max-icon") {
            Image(uiImage: img)
                .renderingMode(.original)
        } else if let image = UIImage(
            systemName: section.systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        )?.withRenderingMode(.alwaysTemplate) {
            Image(uiImage: image)
        } else {
            Image(systemName: section.systemImage)
                .font(.system(size: 17, weight: .medium))
        }
        Text(title)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

private extension AppSection {
    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .files: return "folder.fill"
        case .patches: return "shippingbox.fill"
        case .freeFire: return "flame.fill"
        case .freeFireMax: return "flame.circle.fill"
        case .profile: return "person.fill"
        case .support: return "headphones.circle.fill"
        case .bundleExplorer: return "folder.badge.gearshape"
        }
    }
}
