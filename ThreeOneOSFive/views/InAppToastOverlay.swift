import SwiftUI

// MARK: - InAppToastOverlay
//
// Renders the active toast at the top of the screen.
// The NotificationService drives a queue so rapid toasts are never dropped.
// Each toast shows:
//   • type icon + badge
//   • title + message (2 lines)
//   • link button (if linkTitle is provided) — taps open the URL
//   • dismiss X button

struct InAppToastOverlay: View {
    @ObservedObject var service = NotificationService.shared

    var body: some View {
        VStack(spacing: 0) {
            if let toast = service.activeToast {
                toastBanner(toast)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal:   .move(edge: .top).combined(with: .opacity)
                    ))
                    .id(toast.id)   // forces SwiftUI to animate between different toasts
            }

            // Queue count badge (debug-friendly; hidden in production)
            #if DEBUG
            if service.toastQueue.count > 0 {
                Text("+\(service.toastQueue.count) más")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 2)
            }
            #endif

            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: service.activeToast?.id)
    }

    @ViewBuilder
    private func toastBanner(_ toast: InAppToastItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // ── Top row ──────────────────────────────────────────
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(toast.type.color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: toast.type.icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(toast.type.color)
                }

                // Badge + title
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(toast.type.badgeText)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(toast.type.color)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(toast.type.color.opacity(0.15))
                            .clipShape(Capsule())

                        if toast.isUrgent {
                            Text("URGENTE")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(Color(hex: "EF4444"))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color(hex: "EF4444").opacity(0.15))
                                .clipShape(Capsule())
                        }

                        Text(toast.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    Text(toast.message)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "CBD5E1"))
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                Spacer(minLength: 4)

                // Dismiss button
                Button {
                    service.dismissToast()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "64748B"))
                        .padding(6)
                }
            }

            // ── Link button row (only when linkTitle is provided) ──
            if let linkTitle = toast.linkTitle, let linkURLStr = toast.linkURL,
               let url = URL(string: linkURLStr) {
                Button {
                    UIApplication.shared.open(url)
                    service.dismissToast()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(linkTitle)
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(toast.type.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(toast.type.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: "0F101A").opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(toast.type.color.opacity(toast.isUrgent ? 0.7 : 0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 6)
        .shadow(color: toast.type.color.opacity(0.25), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap anywhere (except link button) opens URL or notifications sheet
            if let link = toast.linkURL, let url = URL(string: link) {
                UIApplication.shared.open(url)
            } else {
                service.showNotificationsSheet = true
            }
            service.dismissToast()
        }
    }
}
