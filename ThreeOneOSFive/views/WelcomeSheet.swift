import SwiftUI

struct WelcomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with logo
                VStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Welcome to X")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("Free Fire Patches & Mods")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Social links
                VStack(spacing: 12) {
                    Text("Join Our Community")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    socialLink(
                        icon: "message.fill",
                        title: "Discord Server",
                        color: .blue,
                        url: "https://discord.gg/AksKwSWaKq"
                    )
                    
                    socialLink(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "WhatsApp Group",
                        color: .green,
                        url: "https://chat.whatsapp.com/LMi0ORfWlDd6iDl0CIvryM"
                    )
                    
                    socialLink(
                        icon: "megaphone.fill",
                        title: "WhatsApp Channel",
                        color: .green,
                        url: "https://whatsapp.com/channel/0029Vb8Pvbk0QeaiLOyydq1w"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Info text
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("Check the Free Fire tab for patches")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("All patches are pre-installed and ready")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, 20)
                
                // Get Started button
                Button {
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
    
    private func socialLink(icon: String, title: String, color: Color, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 28)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}
