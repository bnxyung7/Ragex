import SwiftUI

struct RepositoryHomeView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    @State private var showCompatibility = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {

                        // Hero Header — App Logo
                        VStack(spacing: 0) {
                            AppLogo(size: 52)
                                .padding(.top, 16)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 4)

                        // Device Status
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("ESTADO DEL DISPOSITIVO")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(hex: "475569"))
                                Spacer()
                                HStack(spacing: 6) {
                                    PulseStatusDot(color: Color(hex: "10B981"))
                                    Text("ACTIVO")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color(hex: "10B981"))
                                }
                            }
                            .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                DeviceInfoRow(
                                    icon: "iphone",
                                    label: language.text("dashboard.hardware_model").uppercased(),
                                    value: AppInfo.hardwareDisplayName.uppercased()
                                )
                                Divider().background(Color.white.opacity(0.04)).padding(.leading, 48)
                                DeviceInfoRow(
                                    icon: "gearshape.2",
                                    label: language.text("dashboard.ios_version").uppercased(),
                                    value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))"
                                )
                                Divider().background(Color.white.opacity(0.04)).padding(.leading, 48)
                                CompatibilityRow(isSupported: true, language: language)
                            }
                            .obsidianCard(cornerRadius: 18, borderColor: Color.white.opacity(0.07))
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("PLATAFORMA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "475569"))
                                .padding(.horizontal, 4)

                            Button {
                                showCompatibility = true
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(hex: "10B981").opacity(0.10))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 17))
                                            .foregroundStyle(Color(hex: "10B981"))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("VERSIONES SOPORTADAS")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text("IOS 15 – 18  ·  IOS 26 – 27+")
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(Color(hex: "64748B"))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color(hex: "475569"))
                                }
                                .padding(14)
                            }
                            .buttonStyle(.plain)
                            .obsidianCard(cornerRadius: 14, borderColor: Color.white.opacity(0.06))
                        }
                        .padding(.horizontal, 16)

                        ProductCarouselView()
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button { onOpenLogs() } label: {
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(hex: "64748B"))
                        }
                        Button { onOpenSettings() } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(hex: "64748B"))
                        }
                    }
                }
            }
            .sheet(isPresented: $showCompatibility) {
                SupportedVersionsSheet()
            }
        }
    }
}

// MARK: - Supported versions sheet (lightweight — no inline expand freeze)

private struct SupportedPlatformRow: Identifiable {
    let id: String
    let family: String
    let coverage: String
    let status: String
    let isCurrent: Bool
    var compatible: Bool = true
}

private struct SupportedVersionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var rows: [SupportedPlatformRow] {
        let parts = AppInfo.osVersion.split(separator: ".").map { Int($0) ?? 0 }
        let major = parts.first ?? 0
        let minor = parts.count > 1 ? parts[1] : 0
        return [
            SupportedPlatformRow(id: "15", family: "IOS 15 – 16", coverage: "15.0 – 16.7.12", status: "NO COMPATIBLE", isCurrent: major == 15 || major == 16, compatible: false),
            SupportedPlatformRow(id: "17", family: "IOS 17", coverage: ExploitSupportPolicy.verifiedIOS17Range.uppercased(), status: "VERIFICADO", isCurrent: major == 17),
            SupportedPlatformRow(id: "18", family: "IOS 18", coverage: ExploitSupportPolicy.verifiedIOS18Range.uppercased(), status: "VERIFICADO", isCurrent: major == 18),
            SupportedPlatformRow(id: "26", family: "IOS 26.0", coverage: ExploitSupportPolicy.verifiedIOS26Range.uppercased(), status: "VERIFICADO", isCurrent: major == 26 && minor == 0, compatible: true),
            SupportedPlatformRow(id: "26later", family: "IOS 26.1+", coverage: "26.1 – 26.6.2", status: "NO COMPATIBLE", isCurrent: major == 26 && minor >= 1, compatible: false),
            SupportedPlatformRow(id: "27", family: "IOS 27+", coverage: "27.0+", status: "NO COMPATIBLE", isCurrent: major >= 27, compatible: false)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    Section {
                        ForEach(rows) { row in
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(row.family)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                        if row.isCurrent {
                                            Text("ESTE DISPOSITIVO")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(Color(hex: "10B981"))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color(hex: "10B981").opacity(0.12), in: Capsule())
                                        }
                                    }
                                    Text(row.coverage)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Color(hex: "64748B"))
                                }
                                Spacer()
                                Text(row.status)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(row.compatible ? Color(hex: "10B981") : Color(hex: "EF4444"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background((row.compatible ? Color(hex: "10B981") : Color(hex: "EF4444")).opacity(0.10), in: Capsule())
                            }
                            .listRowBackground(Color(hex: "0A0A0A"))
                            .listRowSeparatorTint(Color.white.opacity(0.06))
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("COBERTURA VERIFICADA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "64748B"))
                    } footer: {
                        Text("RANGOS OFICIALES DE KERNEL. ESTE DISPOSITIVO: IOS \(AppInfo.osVersion) (\(AppInfo.osBuild)).")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(hex: "475569"))
                            .textCase(.uppercase)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("VERSIONES SOPORTADAS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("CERRAR") { dismiss() }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "94A3B8"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - DeviceInfoRow
private struct DeviceInfoRow: View {
    var icon: String = "iphone"
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "64748B"))
            }
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "CBD5E1"))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "475569"))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }
}

// MARK: - CompatibilityRow
private struct CompatibilityRow: View {
    let isSupported: Bool
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "10B981").opacity(0.10))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "10B981"))
            }
            Text(language.text("dashboard.compatibility").uppercased())
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "CBD5E1"))
            Spacer()
            CyberBadge(
                text: language.text("dashboard.supported").uppercased(),
                icon: "checkmark",
                color: Color(hex: "10B981")
            )
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }
}

struct RepositoryNewView: View {
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    var body: some View { Text("Removed") }
}

struct RepositorySearchView: View {
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    var body: some View { Text("Removed") }
}
