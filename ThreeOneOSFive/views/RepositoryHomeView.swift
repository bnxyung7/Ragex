import SwiftUI

struct RepositoryHomeView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Device Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text(language.text("dashboard.device"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            DeviceInfoRow(
                                label: language.text("dashboard.hardware_model"),
                                value: AppInfo.displayMachineName
                            )
                            
                            Divider()
                                .padding(.leading, 20)
                            
                            DeviceInfoRow(
                                label: language.text("dashboard.ios_version"),
                                value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))"
                            )
                            
                            Divider()
                                .padding(.leading, 20)
                            
                            CompatibilityRow(
                                isSupported: appState.isSupported,
                                language: language
                            )
                        }
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Verified versions footer
                    Text(language.text("dashboard.verified_footer"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    
                    // Installation Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text(language.text("dashboard.installation"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                        
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.orange)
                                .frame(width: 32)
                            
                            Text(language.text("dashboard.installation_warning"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Product Carousel
                    ProductCarouselView()
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("X")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            onOpenLogs()
                        } label: {
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(AppTheme.accent)
                        }
                        
                        Button {
                            onOpenSettings()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
        }
    }
}

private struct DeviceInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body.monospaced())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

private struct CompatibilityRow: View {
    let isSupported: Bool
    let language: AppLanguage
    
    var body: some View {
        HStack {
            Text(language.text("dashboard.compatibility"))
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSupported ? .green : .red)
                
                Text(language.text(isSupported ? "dashboard.supported" : "dashboard.unsupported"))
                    .font(.body.weight(.medium))
                    .foregroundStyle(isSupported ? .green : .red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
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
