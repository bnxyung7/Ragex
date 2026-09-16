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
            ZStack {
                Color(hex: "08080C").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // App Brand Card
                        HStack(spacing: 16) {
                            AppLogo(size: 52)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("PROJECT X")
                                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white)
                                    
                                    CyberBadge(text: "v\(appVersion)", color: AppTheme.accent)
                                }
                                
                                Text("Motor de Rendimiento y Parches iOS")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "94A3B8"))
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .obsidianCard(cornerRadius: 18, borderColor: AppTheme.accent.opacity(0.3), glowing: true)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        // Theme Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("COLOR DEL TEMA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "94A3B8"))
                                .padding(.horizontal, 4)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(AppThemeColor.allCases) { theme in
                                    Button {
                                        themeManager.setTheme(theme)
                                    } label: {
                                        HStack(spacing: 10) {
                                            Circle()
                                                .fill(theme.gradient)
                                                .frame(width: 22, height: 22)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white.opacity(0.4), lineWidth: themeManager.currentTheme == theme ? 2 : 0)
                                                )
                                                .shadow(color: theme.color.opacity(themeManager.currentTheme == theme ? 0.6 : 0), radius: 6)
                                            
                                            Text(theme.displayName)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(themeManager.currentTheme == theme ? .white : Color(hex: "94A3B8"))
                                            
                                            Spacer()
                                            
                                            if themeManager.currentTheme == theme {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(theme.color)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(themeManager.currentTheme == theme ? Color(hex: "18192A") : Color(hex: "11121A"))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(themeManager.currentTheme == theme ? theme.color.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                        .obsidianCard(cornerRadius: 18, borderColor: Color.white.opacity(0.06))
                        .padding(.horizontal, 16)

                        // Updates & Community
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NOVEDADES Y COMUNIDAD")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "94A3B8"))
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                Button {
                                    showChangelog = true
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(hex: "3B82F6").opacity(0.15))
                                                .frame(width: 34, height: 34)
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 15))
                                                .foregroundStyle(Color(hex: "3B82F6"))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Historial de Versiones")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Text("Ver cambios en la v\(appVersion)")
                                                .font(.caption2)
                                                .foregroundStyle(Color(hex: "94A3B8"))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color(hex: "94A3B8"))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.leading, 58)
                                
                                Link(destination: URL(string: "https://whatsapp.com/channel/0029Vb7NRaRAojYuOAfX5S0S")!) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(hex: "10B981").opacity(0.15))
                                                .frame(width: 34, height: 34)
                                            Image(systemName: "megaphone.fill")
                                                .font(.system(size: 15))
                                                .foregroundStyle(Color(hex: "10B981"))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Canal Oficial de WhatsApp")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Text("Anuncios y descargas")
                                                .font(.caption2)
                                                .foregroundStyle(Color(hex: "94A3B8"))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color(hex: "94A3B8"))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }
                            .obsidianCard(cornerRadius: 18, borderColor: Color.white.opacity(0.06))
                        }
                        .padding(.horizontal, 16)

                        // Preferences & Flags
                        VStack(alignment: .leading, spacing: 10) {
                            Text("HERRAMIENTAS DEL SISTEMA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "94A3B8"))
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                Toggle(isOn: $cleanerEnabled) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(AppTheme.accent.opacity(0.15))
                                                .frame(width: 34, height: 34)
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 15))
                                                .foregroundStyle(AppTheme.accent)
                                        }
                                        Text(language.text("tab.cleaner"))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .tint(AppTheme.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                
                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.leading, 58)
                                
                                Toggle(isOn: $developerModeEnabled) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(hex: "F59E0B").opacity(0.15))
                                                .frame(width: 34, height: 34)
                                            Image(systemName: "hammer.fill")
                                                .font(.system(size: 15))
                                                .foregroundStyle(Color(hex: "F59E0B"))
                                        }
                                        Text(language.text("settings.developer_mode"))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .tint(AppTheme.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .obsidianCard(cornerRadius: 18, borderColor: Color.white.opacity(0.06))
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "08080C"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .sheet(isPresented: $showChangelog) {
                NavigationStack {
                    ChangelogView()
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "2.0"
    }
}