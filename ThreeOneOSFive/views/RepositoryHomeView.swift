import SwiftUI

struct RepositoryHomeView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "08080C").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Hero Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.18))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 12)
                                
                                AppLogo(size: 64)
                            }
                            .padding(.top, 10)
                            
                            VStack(spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("PROJECT X")
                                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white)
                                    
                                    CyberBadge(text: "iOS PRO", color: AppTheme.accent)
                                }
                                
                                Text("Motor de Rendimiento y Parches para iOS")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: "94A3B8"))
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Device Status Section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("ESTADO DEL DISPOSITIVO")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(hex: "94A3B8"))
                                Spacer()
                                HStack(spacing: 6) {
                                    PulseStatusDot(color: appState.isSupported ? Color(hex: "10B981") : Color(hex: "EF4444"))
                                    Text(appState.isSupported ? "ONLINE" : "NO COMPATIBLE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(appState.isSupported ? Color(hex: "10B981") : Color(hex: "EF4444"))
                                }
                            }
                            .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                DeviceInfoRow(
                                    icon: "iphone",
                                    label: language.text("dashboard.hardware_model"),
                                    value: AppInfo.displayMachineName
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.leading, 48)
                                
                                DeviceInfoRow(
                                    icon: "gearshape.2",
                                    label: language.text("dashboard.ios_version"),
                                    value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))"
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.leading, 48)
                                
                                CompatibilityRow(
                                    isSupported: appState.isSupported,
                                    language: language
                                )
                            }
                            .obsidianCard(cornerRadius: 18, borderColor: AppTheme.accent.opacity(0.25), glowing: true)
                        }
                        .padding(.horizontal, 16)
                        
                        // Installation Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SISTEMA Y SEGURIDAD")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "94A3B8"))
                                .padding(.horizontal, 4)
                            
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: "F59E0B").opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "shield.lefthalf.filled")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color(hex: "F59E0B"))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Información de Parcheo")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                    
                                    Text(language.text("dashboard.installation_warning"))
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "94A3B8"))
                                        .lineSpacing(2)
                                }
                            }
                            .padding(16)
                            .obsidianCard(cornerRadius: 16, borderColor: Color(hex: "F59E0B").opacity(0.2))
                        }
                        .padding(.horizontal, 16)
                        
                        // Product Carousel (safe empty check)
                        ProductCarouselView()
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "08080C"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        AppLogo(size: 26)
                        Text("PROJECT X")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            onOpenLogs()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "181926"))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        
                        Button {
                            onOpenSettings()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "181926"))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct DeviceInfoRow: View {
    var icon: String = "iphone"
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "94A3B8"))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct CompatibilityRow: View {
    let isSupported: Bool
    let language: AppLanguage
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill((isSupported ? Color(hex: "10B981") : Color(hex: "EF4444")).opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: isSupported ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSupported ? Color(hex: "10B981") : Color(hex: "EF4444"))
            }
            
            Text(language.text("dashboard.compatibility"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            CyberBadge(
                text: language.text(isSupported ? "dashboard.supported" : "dashboard.unsupported"),
                icon: isSupported ? "checkmark" : "xmark",
                color: isSupported ? Color(hex: "10B981") : Color(hex: "EF4444")
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// Empty placeholder views for removed functionality
struct RepositoryNewView: View {
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    
    var body: some View {
        Text("Removed")
    }
}

struct RepositorySearchView: View {
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    
    var body: some View {
        Text("Removed")
    }
}
