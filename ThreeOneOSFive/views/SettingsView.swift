import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var patchStore: PatchProjectStore
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage(FeatureVisibility.cleanerStorageKey) private var cleanerEnabled = true
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false
    @State private var showChangelog = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastIcon = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        AppLogo()

                        VStack(alignment: .leading, spacing: 3) {
                            Text("X").font(.headline)
                            Text(language.text("common.version", appVersion))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button {
                        showChangelog = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Updates")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Version \(appVersion)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                
                Section {
                    Link(destination: URL(string: "https://discord.gg/AksKwSWaKq")!) {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundStyle(.blue)
                            Text("Join Discord for Updates")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .font(.subheadline)
                    }
                    
                    Link(destination: URL(string: "https://chat.whatsapp.com/LMi0ORfWlDd6iDl0CIvryM")!) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .foregroundStyle(.green)
                            Text("Join WhatsApp Group")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .font(.subheadline)
                    }
                    
                    Link(destination: URL(string: "https://whatsapp.com/channel/0029Vb8Pvbk0QeaiLOyydq1w")!) {
                        HStack {
                            Image(systemName: "megaphone.fill")
                                .foregroundStyle(.green)
                            Text("Follow WhatsApp Channel")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .font(.subheadline)
                    }
                } header: {
                    Text("Community")
                }

                Section {
                    Toggle(isOn: $cleanerEnabled) {
                        Label(language.text("tab.cleaner"), systemImage: "sparkles")
                    }
                    Toggle(isOn: $developerModeEnabled) {
                        Label(
                            language.text("settings.developer_mode"),
                            systemImage: "hammer.fill"
                        )
                    }
                } header: {
                    Text(language.text("dashboard.features"))
                } footer: {
                    Text(language.text("settings.developer_mode_footer"))
                }

                // Theme Selector
                Section {
                    ForEach(AppThemeColor.allCases) { theme in
                        Button {
                            themeManager.setTheme(theme)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: theme.icon)
                                    .font(.title2)
                                    .foregroundStyle(theme.color)
                                
                                Text(theme.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(theme.color)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Tema")
                } footer: {
                    Text("Selecciona el color del tema de la aplicación")
                }

                Section(language.text("common.device")) {
                    LabeledContent(language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
                    LabeledContent(language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                }

                Section {
                    HStack {
                        Text(language.text("settings.current_version"))
                        Spacer()
                        Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                        .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                    }
                    LabeledContent("iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range)
                    LabeledContent("iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range)
                    LabeledContent("iOS 26", value: ExploitSupportPolicy.verifiedIOS26Range)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iOS 27.0")
                            .font(.body)
                        ForEach(ExploitSupportPolicy.verifiedIOS27Builds, id: \.build) { version in
                            Text(versionLabel(version))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text(language.text("settings.verified_versions"))
                } footer: {
                    Text(language.text("settings.supported_versions_footer"))
                }
            }
            .tint(AppTheme.accent)
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showChangelog) {
                NavigationStack {
                    ChangelogView()
                }
            }
            .overlay(alignment: .top) {
                if showToast {
                    ToastView(message: toastMessage, icon: toastIcon)
                        .padding(.top, 50)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
    }

    private func versionLabel(
        _ version: (beta: Int, publicBeta: Int?, build: String)
    ) -> String {
        if let publicBeta = version.publicBeta {
            return language.text(
                "settings.developer_public_beta_build",
                Int64(version.beta),
                Int64(publicBeta),
                version.build
            )
        }
        return language.text(
            "settings.developer_beta_build",
            Int64(version.beta),
            version.build
        )
    }
    
    private func checkBundlePatches() -> String {
        guard let url = Bundle.main.url(forResource: "PreinstalledPatches", withExtension: nil) else {
            return "NOT FOUND"
        }
        
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension.lowercased() == "3105" }) else {
            return "ERROR"
        }
        
        return files.map { $0.lastPathComponent }.joined(separator: ", ")
    }
}

struct ToastView: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.green)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}
