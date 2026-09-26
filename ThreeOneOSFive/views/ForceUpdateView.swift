import SwiftUI

/// Blocks the app when the server rejects the installed version.
struct ForceUpdateView: View {
    let versionStatus: KeyAPIService.VersionStatusResponse

    private var isNotice: Bool {
        versionStatus.presentation == "notice"
    }

    private struct NoticeLine: Identifiable {
        let id: Int
        let title: String
        let text: String
    }

    private struct NoticeAction: Identifiable {
        let id: Int
        let title: String
        let url: URL
    }

    private var noticeLines: [NoticeLine] {
        if let items = versionStatus.notice?.items, !items.isEmpty {
            return items.enumerated().compactMap { index, item in
                let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let text = item.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !title.isEmpty || !text.isEmpty else { return nil }
                return NoticeLine(id: index, title: title, text: text)
            }
        }
        return (versionStatus.message ?? "")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { NoticeLine(id: $0.offset, title: "", text: $0.element) }
    }

    private var noticeActions: [NoticeAction] {
        let buttons = [
            versionStatus.notice?.primaryButton,
            versionStatus.notice?.secondaryButton
        ]
        var actions: [NoticeAction] = []
        for button in buttons {
            guard
                let title = button?.title?.trimmingCharacters(in: .whitespacesAndNewlines),
                !title.isEmpty,
                let rawURL = button?.url?.trimmingCharacters(in: .whitespacesAndNewlines),
                let url = URL(string: rawURL),
                !rawURL.isEmpty
            else { continue }
            actions.append(NoticeAction(id: actions.count, title: title, url: url))
        }
        if actions.isEmpty,
           let rawURL = versionStatus.contactURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           let url = URL(string: rawURL),
           !rawURL.isEmpty {
            actions.append(NoticeAction(id: 0, title: "Abrir enlace", url: url))
        }
        return actions
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
                        Text(noticeLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.4)
                            .foregroundStyle(Color(hex: "94A3B8"))

                        Text(noticeHeading)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        ForEach(noticeLines) { line in
                            noticeRow(number: line.id + 1, title: line.title, text: line.text)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 24)
            }

            if !noticeActions.isEmpty {
                VStack(spacing: 10) {
                    ForEach(noticeActions) { action in
                        Button {
                            UIApplication.shared.open(action.url)
                        } label: {
                            Text(action.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(action.id == 0 ? Color(hex: "06060E") : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(action.id == 0 ? Color.white : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(action.id == 0 ? 0 : 0.35), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    private var noticeLabel: String {
        let label = versionStatus.notice?.label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return label.isEmpty ? "AVISO" : label
    }

    private var noticeHeading: String {
        let title = versionStatus.notice?.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !title.isEmpty { return title }
        let fallback = versionStatus.noticeTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return fallback.isEmpty ? "Aviso" : fallback
    }

    private func noticeRow(number: Int, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(format: "%02d", number))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "06060E"))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white))

            VStack(alignment: .leading, spacing: 4) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !text.isEmpty {
                    Text(text)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(hex: "E2E8F0"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, title.isEmpty ? 6 : 2)
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
