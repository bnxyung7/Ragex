import SwiftUI

struct NotificationsCenterView: View {
    @ObservedObject var service = NotificationService.shared
    @ObservedObject var pushService = PushNotificationService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Push permission banner (only when denied or not determined)
                        if pushService.permissionDetermined && !pushService.permissionGranted {
                            pushPermissionBanner
                        }

                        // Header
                        headerCard

                        // Messages
                        if service.notifications.isEmpty && service.broadcastMessages.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 10) {
                                // Server notifications first (from new push system)
                                ForEach(service.notifications) { notification in
                                    serverNotificationCard(notification)
                                }
                                
                                // Then broadcast messages
                                ForEach(service.broadcastMessages) { message in
                                    messageCard(message)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle("Centro de Mensajes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await service.fetchAdminBroadcasts() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Refrescar")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(AppTheme.accent)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        service.markAllAsRead()
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                }
            }
            .onAppear {
                service.markAllAsRead()
            }
        }
    }

    // MARK: - Push permission banner

    private var pushPermissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: "F59E0B"))

            VStack(alignment: .leading, spacing: 2) {
                Text("Notificaciones Desactivadas")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text("Actívalas en Ajustes para recibir alertas del admin aunque la app esté cerrada.")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "CBD5E1"))
                    .lineSpacing(2)
            }

            Spacer()

            Button {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Activar")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "F59E0B"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(hex: "F59E0B").opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "F59E0B").opacity(0.30), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Canal de Avisos Directo")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)

                    Text("ADMIN")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                }

                Text("Comunicados enviados directamente por la administración.")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "94A3B8"))
            }
            Spacer()

            // Unread count badge
            if service.unreadCount > 0 {
                Text("\(service.unreadCount)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color(hex: "EF4444"))
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .obsidianCard(cornerRadius: 16, borderColor: AppTheme.accent.opacity(0.25), glowing: true)
    }

    // MARK: - Message card

    // Server notification card (new push notification system)
    private func serverNotificationCard(_ notif: ServerNotification) -> some View {
        let isUnread = !service.isRead(notif.id)
        let isUrgent = notif.priority == "urgent" || notif.priority == "high"
        let accentCol = notif.priorityBadgeColor

        return VStack(alignment: .leading, spacing: 12) {
            // Top bar: type badge + priority + unread dot
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(accentCol)
                        .frame(width: 6, height: 6)
                    Text("\(notif.icon) \(notif.type.uppercased())")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(accentCol)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(accentCol.opacity(0.15))
                .clipShape(Capsule())
                
                // Priority badge
                if notif.priority != "normal" {
                    Text(notif.priority.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(notif.priorityBadgeColor)
                        .clipShape(Capsule())
                }

                Spacer()

                // Unread dot
                if isUnread {
                    Circle()
                        .fill(Color(hex: "3B82F6"))
                        .frame(width: 8, height: 8)
                }

                Text(notif.date.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "64748B"))
            }

            // Title
            Text(notif.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isUrgent ? Color(hex: "FCA5A5") : .white)

            // Message
            Text(notif.message)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "CBD5E1"))
                .lineSpacing(3)
            
            // Image if provided
            if !notif.imageUrl.isEmpty, let url = URL(string: notif.imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        EmptyView()
                    case .empty:
                        ProgressView()
                            .frame(height: 160)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // Action button if provided
            if !notif.actionButton.isEmpty, !notif.actionUrl.isEmpty, let url = URL(string: notif.actionUrl) {
                Divider()
                    .background(Color.white.opacity(0.08))

                Button {
                    service.trackNotificationClick(notif.id)
                    UIApplication.shared.open(url)
                } label: {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 13))
                        Text(notif.actionButton)
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(accentCol)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            
            // Regular link if no action button but link exists
            else if !notif.link.isEmpty, let url = URL(string: notif.link) {
                Divider()
                    .background(Color.white.opacity(0.08))

                Link(destination: url) {
                    HStack {
                        Image(systemName: "link")
                            .font(.system(size: 13))
                        Text("Ver más")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(accentCol)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .obsidianCard(
            cornerRadius: 16,
            borderColor: isUrgent ? Color(hex: "EF4444").opacity(0.4) : Color.white.opacity(0.06),
            glowing: isUrgent
        )
        .overlay(alignment: .topLeading) {
            if isUnread {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "3B82F6"))
                    .frame(width: 3, height: 40)
                    .padding(.leading, 0)
                    .padding(.top, 12)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
        .onTapGesture {
            service.markAsRead(notif.id)
        }
    }

    // MARK: - Message card

    private func messageCard(_ msg: AdminBroadcastMessage) -> some View {
        let isUnread  = !service.readMessageIDs.contains(msg.id)
        let isUrgent  = msg.isUrgent == true
        let accentCol = isUrgent ? Color(hex: "EF4444") : AppTheme.accent

        return VStack(alignment: .leading, spacing: 10) {
            // Top bar: badge + unread dot + timestamp
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(accentCol)
                        .frame(width: 6, height: 6)
                    Text(isUrgent ? "⚠️ URGENTE" : "MENSAJE OFICIAL")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(accentCol)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(accentCol.opacity(0.15))
                .clipShape(Capsule())

                Spacer()

                // Unread dot
                if isUnread {
                    Circle()
                        .fill(Color(hex: "3B82F6"))
                        .frame(width: 8, height: 8)
                }

                Text(msg.timestamp)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "64748B"))
            }

            Text(msg.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isUrgent ? Color(hex: "FCA5A5") : .white)

            Text(msg.message)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "CBD5E1"))
                .lineSpacing(3)

            if let link = msg.linkURL, let url = URL(string: link) {
                Divider()
                    .background(Color.white.opacity(0.08))

                Link(destination: url) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 13))
                        Text(msg.linkTitle ?? "Interactuar / Responder")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(accentCol)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .obsidianCard(
            cornerRadius: 16,
            borderColor: isUrgent ? Color(hex: "EF4444").opacity(0.4) : Color.white.opacity(0.06),
            glowing: isUrgent
        )
        .overlay(alignment: .topLeading) {
            if isUnread {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "3B82F6"))
                    .frame(width: 3, height: 40)
                    .padding(.leading, 0)
                    .padding(.top, 12)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
        .onTapGesture {
            service.markAsRead(id: msg.id)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "64748B"))
            Text("No hay mensajes nuevos")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Los avisos del administrador aparecerán aquí en tiempo real.")
                .font(.caption)
                .foregroundStyle(Color(hex: "94A3B8"))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .obsidianCard(cornerRadius: 16)
    }
}
