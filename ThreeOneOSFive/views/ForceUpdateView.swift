import SwiftUI

/// Blocks the app when the server rejects the installed version.
struct ForceUpdateView: View {
    let versionStatus: KeyAPIService.VersionStatusResponse

    private var isNotice: Bool {
        versionStatus.presentation == "notice"
    }

    private var noticeParagraphs: [String] {
        (versionStatus.message ?? "")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        ZStack {
            Color(hex: "06060E")
                .ignoresSafeArea()

            if isNotice {
                noticeContent
            } else {
                updateContent
            }
        }
    }

    private var noticeContent: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AVISO")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.4)
                            .foregroundStyle(Color(hex: "94A3B8"))

                        Text(versionStatus.noticeTitle ?? "Servicio en pausa")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        ForEach(Array(noticeParagraphs.enumerated()), id: \.offset) { index, paragraph in
                            noticeRow(number: index + 1, text: paragraph)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 24)
            }

            if let contactURL = versionStatus.contactURL, let url = URL(string: contactURL), !contactURL.isEmpty {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Escribir por WhatsApp")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "06060E"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    private func noticeRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(format: "%02d", number))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "06060E"))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white))

            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(hex: "E2E8F0"))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var updateContent: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "EF4444").opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(Color(hex: "EF4444").opacity(0.4), lineWidth: 2)
                    .frame(width: 140, height: 140)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(Color(hex: "EF4444"))
            }

            VStack(spacing: 16) {
                Text("Actualización Requerida")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if let message = versionStatus.message {
                    Text(message)
                        .font(.body)
                        .foregroundStyle(Color(hex: "94A3B8"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                } else {
                    Text("Esta versión de la aplicación ya no está disponible. Por favor, actualiza a la última versión para continuar.")
                        .font(.body)
                        .foregroundStyle(Color(hex: "94A3B8"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            VStack(spacing: 12) {
                versionInfoRow(
                    label: "Versión actual",
                    value: versionStatus.currentVersion,
                    color: "EF4444"
                )

                if let minimumVersion = versionStatus.minimumVersion {
                    versionInfoRow(
                        label: "Versión mínima",
                        value: minimumVersion,
                        color: "F59E0B"
                    )
                }

                if let latestVersion = versionStatus.latestVersion {
                    versionInfoRow(
                        label: "Última versión",
                        value: latestVersion,
                        color: "10B981"
                    )
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            if let downloadURL = versionStatus.downloadURL, let url = URL(string: downloadURL) {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Descargar Actualización")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "10B981"),
                                        Color(hex: "059669")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: "10B981").opacity(0.5), radius: 20, x: 0, y: 10)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }

    private func versionInfoRow(label: String, value: String, color: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "94A3B8"))
            }

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
    }
}
