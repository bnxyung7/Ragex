import SwiftUI

struct SupportView: View {
    @Environment(\.appLanguage) private var language
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showCopiedAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.18))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 10)
                                
                                Image(systemName: "headphones.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .padding(.top, 16)
                            
                            VStack(spacing: 4) {
                                Text(language.text("support.center_title"))
                                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text(language.text("support.center_subtitle"))
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: "94A3B8"))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // WhatsApp Official Card
                        SupportCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            badge: language.text("support.badge_official"),
                            title: language.text("support.whatsapp_official"),
                            subtitle: language.text("support.whatsapp_fast"),
                            color: Color(hex: "10B981"),
                            detail: SupportContact.whatsappNumber
                        ) {
                            openWhatsApp()
                        }
                        
                        // WhatsApp Channel Card
                        SupportCard(
                            icon: "megaphone.fill",
                            badge: language.text("support.badge_channel"),
                            title: language.text("support.news_channel"),
                            subtitle: language.text("support.news_channel_desc"),
                            color: AppTheme.accent,
                            detail: language.text("support.follow_whatsapp")
                        ) {
                            openChannel()
                        }
                        
                        // Developer Verification Card
                        VStack(spacing: 14) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "8B5CF6").opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Color(hex: "8B5CF6"))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(SupportContact.developerName)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                        CyberBadge(text: "DEV", color: Color(hex: "8B5CF6"))
                                    }
                                    
                                    Text(language.text("support.official_developer"))
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "94A3B8"))
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.08))
                            
                            HStack {
                                Text(language.text("support.contact_label"))
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "94A3B8"))
                                
                                Spacer()
                                
                                Button {
                                    copyToClipboard(SupportContact.whatsappNumber)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption2)
                                        Text(SupportContact.whatsappNumber)
                                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "181926"))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .obsidianCard(cornerRadius: 18, borderColor: Color.white.opacity(0.08))
                        
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle(language.supportTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .overlay(
            Group {
                if showCopiedAlert {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "10B981"))
                            
                            Text(language.supportCopiedMessage)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(hex: "181926"))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "10B981").opacity(0.4), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.5), radius: 12)
                        )
                        .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: showCopiedAlert)
                }
            }
        )
    }
    
    // MARK: - Actions
    private func openWhatsApp() {
        let number = SupportContact.whatsappNumber.replacingOccurrences(of: "+", with: "")
        let message = language.text("support.whatsapp_prefill")
        let urlString = "https://wa.me/\(number)?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openChannel() {
        if let url = URL(string: "https://whatsapp.com/channel/0029Vb7NRaRAojYuOAfX5S0S") {
            UIApplication.shared.open(url)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation {
            showCopiedAlert = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedAlert = false
            }
        }
    }
}

// MARK: - Support Card Component
struct SupportCard: View {
    let icon: String
    var badge: String? = nil
    let title: String
    let subtitle: String
    let color: Color
    let detail: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(color.opacity(0.16))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        
                        if let badge = badge {
                            CyberBadge(text: badge, color: color)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "94A3B8"))
                    
                    Text(detail)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(color)
                        .padding(.top, 1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "94A3B8"))
            }
            .padding(16)
            .obsidianCard(cornerRadius: 18, borderColor: color.opacity(0.25), glowing: false)
        }
        .buttonStyle(SupportCardButtonStyle())
    }
}

// MARK: - Button Style
struct SupportCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}