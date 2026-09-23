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
                                    label: language.text("dashboard.hardware_model"),
                                    value: AppInfo.hardwareDisplayName
                                )
                                Divider().background(Color.white.opacity(0.04)).padding(.leading, 48)
                                DeviceInfoRow(
                                    icon: "gearshape.2",
                                    label: language.text("dashboard.ios_version"),
                                    value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))"
                                )
                                Divider().background(Color.white.opacity(0.04)).padding(.leading, 48)
                                CompatibilityRow(isSupported: true, language: language)
                            }
                            .obsidianCard(cornerRadius: 18, borderColor: Color.white.opacity(0.07))
                        }
                        .padding(.horizontal, 16)

                        // Versiones Compatibles
                        VStack(alignment: .leading, spacing: 8) {
                            Text("VERSIONES COMPATIBLES")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "475569"))
                                .padding(.horizontal, 4)

                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showCompatibility.toggle()
                                }
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
                                        Text("Versiones soportadas")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("iOS 15 – iOS 18 · iOS 26+")
                                            .font(.caption2)
                                            .foregroundStyle(Color(hex: "475569"))
                                    }
                                    Spacer()
                                    Image(systemName: showCompatibility ? "chevron.up" : "chevron.down")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color(hex: "475569"))
                                }
                                .padding(14)
                            }
                            .buttonStyle(.plain)
                            .obsidianCard(cornerRadius: 14, borderColor: Color.white.opacity(0.06))

                            if showCompatibility {
                                VStack(spacing: 6) {
                                    CompatVersionGroup(title: "iOS 15 – iOS 16", versions: "15.0 – 16.7.x", color: Color(hex: "94A3B8"))
                                    CompatVersionGroup(title: "iOS 17", versions: "17.0 · 17.0.1 · 17.0.2 · 17.0.3 · 17.1 · 17.1.1 · 17.1.2 · 17.2 · 17.2.1 · 17.3 · 17.3.1 · 17.4 · 17.4.1 · 17.5 · 17.5.1 · 17.6 · 17.6.1 · 17.7.x", color: Color(hex: "94A3B8"))
                                    CompatVersionGroup(title: "iOS 18", versions: "18.0 · 18.0.1 · 18.1 · 18.1.1 · 18.2 · 18.2.1 · 18.3 · 18.3.1 · 18.3.2 · 18.4 · 18.4.1 · 18.5 · 18.6 · 18.6.1 · 18.7.x", color: Color(hex: "94A3B8"))
                                    CompatVersionGroup(title: "iOS 26", versions: "26.0 · 26.0.1 · 26.1 · 26.2 · 26.3 · 26.4 · 26.5 · 26.6 · 26.6.1 · 26.6.2", color: Color(hex: "94A3B8"))
                                    CompatVersionGroup(title: "iOS 27+", versions: "27.0 · 27.1+ Soportado", color: Color(hex: "10B981"))
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
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
        }
    }
}

// MARK: - CompatVersionGroup
private struct CompatVersionGroup: View {
    let title: String
    let versions: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
            Text(versions)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "475569"))
                .lineSpacing(2)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1)))
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
            Text(language.text("dashboard.compatibility"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "CBD5E1"))
            Spacer()
            CyberBadge(
                text: language.text("dashboard.supported"),
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
