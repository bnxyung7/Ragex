import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @AppStorage(AppLanguage.storageKey) private var languageCode = ""
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var patchStore: PatchProjectStore
    @ObservedObject private var activationStore = PatchActivationStore.shared
    @State private var showClearConfirm = false
    @State private var showResetDone = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // App Brand Card
                        HStack(spacing: 14) {
                            AppLogo(size: 46)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("X")
                                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("v\(appVersion)")
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: "475569"))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(hex: "0A0A0A"), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 1))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(language.text("language.section"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "475569"))
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, option in
                                    Button {
                                        languageCode = option.rawValue
                                        UserDefaults.standard.set(true, forKey: "x.language.userChosen")
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text(option.codeLabel)
                                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                                .foregroundStyle(selectedLanguage.rawValue == option.rawValue ? .black : .white)
                                                .frame(width: 38, height: 38)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .fill(selectedLanguage.rawValue == option.rawValue ? Color.white : Color.white.opacity(0.06))
                                                )
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(option.nativeName.uppercased())
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                Text(option.regionLabel)
                                                    .font(.caption2)
                                                    .foregroundStyle(Color(hex: "475569"))
                                            }
                                            Spacer()
                                            if selectedLanguage.rawValue == option.rawValue {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Color(hex: "10B981"))
                                            }
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 12)
                                    }
                                    .buttonStyle(.plain)
                                    if index < AppLanguage.allCases.count - 1 {
                                        Divider().background(Color.white.opacity(0.05)).padding(.leading, 52)
                                    }
                                }
                            }
                            .background(Color(hex: "0A0A0A"), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))

                            Text(language.text("language.footer"))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color(hex: "475569"))
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(language.text("settings.activation"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "475569"))
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "64748B").opacity(0.10))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color(hex: "64748B"))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(language.text("settings.history_toggle"))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text(language.text("settings.history_toggle_sub"))
                                            .font(.caption2)
                                            .foregroundStyle(Color(hex: "475569"))
                                    }
                                    Spacer()
                                    Toggle("", isOn: $activationStore.historyEnabled)
                                        .labelsHidden()
                                        .tint(Color(hex: "10B981"))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                                Divider().background(Color.white.opacity(0.05)).padding(.leading, 52)

                                Button {
                                    activationStore.clearHistory()
                                    toastMessage = language.text("settings.history_cleared")
                                    withAnimation { showResetDone = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { showResetDone = false }
                                    }
                                } label: {
                                    SettingsRow(
                                        icon: "trash",
                                        iconColor: Color(hex: "EF4444"),
                                        title: language.text("settings.history_clear"),
                                        subtitle: language.text("settings.history_clear_sub")
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .background(Color(hex: "0A0A0A"), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        }
                        .padding(.horizontal, 16)

                        // Herramientas
                        VStack(alignment: .leading, spacing: 10) {
                            Text("HERRAMIENTAS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "475569"))
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {

                                // Reiniciar Exploit
                                Button {
                                    appState.forceRerunKernelExploit()
                                    toastMessage = "Exploit reiniciado ✓"
                                    withAnimation { showResetDone = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { showResetDone = false }
                                    }
                                } label: {
                                    SettingsRow(icon: "bolt.fill", iconColor: Color(hex: "F59E0B"), title: "Reiniciar Exploit", subtitle: "Fuerza re-ejecución del exploit en el dispositivo")
                                }
                                .buttonStyle(.plain)

                                Divider().background(Color.white.opacity(0.05)).padding(.leading, 52)

                                // Limpiar Caché
                                Button { showClearConfirm = true } label: {
                                    SettingsRow(icon: "trash.fill", iconColor: Color(hex: "EF4444"), title: "Limpiar Caché", subtitle: "Libera archivos temporales y memoria caché")
                                }
                                .buttonStyle(.plain)

                                Divider().background(Color.white.opacity(0.05)).padding(.leading, 52)

                                // Forzar Actualización
                                Button {
                                    appState.detectSupport()
                                    toastMessage = "Estado actualizado ✓"
                                    withAnimation { showResetDone = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { showResetDone = false }
                                    }
                                } label: {
                                    SettingsRow(icon: "arrow.clockwise", iconColor: Color(hex: "10B981"), title: "Forzar Actualización", subtitle: "Re-verifica compatibilidad del dispositivo")
                                }
                                .buttonStyle(.plain)
                            }
                            .background(Color(hex: "0A0A0A"), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        }
                        .padding(.horizontal, 16)

                        // Grupo
                        VStack(alignment: .leading, spacing: 10) {
                            Text("GRUPO")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "475569"))
                                .padding(.horizontal, 4)

                            Link(destination: URL(string: "https://whatsapp.com/channel/0029Vb7NRaRAojYuOAfX5S0S")!) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "10B981").opacity(0.10))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "megaphone.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color(hex: "10B981"))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Canal Oficial de WhatsApp")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("Anuncios y descargas")
                                            .font(.caption2)
                                            .foregroundStyle(Color(hex: "475569"))
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color(hex: "475569"))
                                }
                                .padding(.horizontal, 14).padding(.vertical, 12)
                            }
                            .background(Color(hex: "0A0A0A"), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                }

                // Toast
                if showResetDone {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(Color(hex: "10B981").opacity(0.9), in: Capsule())
                            .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "94A3B8"))
                }
            }
            .confirmationDialog("¿Deseas limpiar la memoria caché temporal?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Limpiar Caché", role: .destructive) {
                    clearTemporaryCaches()
                    toastMessage = "Caché liberado ✓"
                    withAnimation { showResetDone = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showResetDone = false }
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? language
    }

    private func clearTemporaryCaches() {
        let fileManager = FileManager.default
        // 1. Clear tmp directory
        let tmpDir = NSTemporaryDirectory()
        if let tmpFiles = try? fileManager.contentsOfDirectory(atPath: tmpDir) {
            for file in tmpFiles {
                try? fileManager.removeItem(atPath: (tmpDir as NSString).appendingPathComponent(file))
            }
        }
        // 2. Clear Caches directory
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            if let cacheFiles = try? fileManager.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil) {
                for fileURL in cacheFiles {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        }
        URLCache.shared.removeAllCachedResponses()
        if DevicePatchService.appliedReceipts().isEmpty {
            PatchActivationStore.shared.resetAllActivations()
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "3.1.7"
    }
}

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.10))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "475569"))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "2D2D2D"))
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }
}
