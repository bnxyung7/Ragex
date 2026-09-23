import SwiftUI

struct AnnouncementModalView: View {
    @ObservedObject var service = AnnouncementService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Status Card
                        headerStatusCard
                        
                        // Announcements List
                        VStack(spacing: 14) {
                            ForEach(service.announcements) { announcement in
                                announcementCard(announcement)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle("Anuncios y Noticias")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await service.fetchAnnouncements()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if service.isFetching {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accent))
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text("Actualizar")
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
    
    private var headerStatusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.18))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Canal en Tiempo Real")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "10B981"))
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color(hex: "10B981"))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: "10B981").opacity(0.15))
                    .clipShape(Capsule())
                }
                
                Text("Noticias oficiales, estados de servidores y parches para X iOS.")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "94A3B8"))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(14)
        .obsidianCard(cornerRadius: 16, borderColor: AppTheme.accent.opacity(0.25), glowing: true)
    }
    
    private func announcementCard(_ item: LiveAnnouncement) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                // Tag badge
                Text(item.tag)
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tagBackground(item.tagColor))
                    .foregroundStyle(tagForeground(item.tagColor))
                    .clipShape(Capsule())
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(item.timestamp)
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(Color(hex: "64748B"))
            }
            
            Text(item.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Text(item.message)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "CBD5E1"))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            
            if let linkURL = item.linkURL, let url = URL(string: linkURL) {
                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.top, 2)
                
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 14))
                        Text(item.linkTitle ?? "Más Información")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.accent)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .obsidianCard(
            cornerRadius: 16,
            borderColor: item.isImportant ? AppTheme.accent.opacity(0.35) : Color.white.opacity(0.06),
            glowing: item.isImportant
        )
    }
    
    private func tagBackground(_ color: String) -> Color {
        switch color.lowercased() {
        case "purple": return AppTheme.accent.opacity(0.2)
        case "emerald", "green": return Color(hex: "10B981").opacity(0.2)
        case "amber", "yellow", "orange": return Color(hex: "F59E0B").opacity(0.2)
        case "rose", "red": return Color(hex: "EF4444").opacity(0.2)
        case "blue": return Color(hex: "3B82F6").opacity(0.2)
        default: return AppTheme.accent.opacity(0.2)
        }
    }
    
    private func tagForeground(_ color: String) -> Color {
        switch color.lowercased() {
        case "purple": return AppTheme.accent
        case "emerald", "green": return Color(hex: "10B981")
        case "amber", "yellow", "orange": return Color(hex: "F59E0B")
        case "rose", "red": return Color(hex: "EF4444")
        case "blue": return Color(hex: "3B82F6")
        default: return AppTheme.accent
        }
    }
}
