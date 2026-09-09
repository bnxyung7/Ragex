import SwiftUI

struct SupportView: View {
    @Environment(\.appLanguage) private var language
    @State private var showCopiedAlert = false
    
    // Detectar idioma del sistema
    private var isSpanish: Bool {
        Locale.current.language.languageCode?.identifier == "es"
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "headphones.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [SupportTheme.primary, SupportTheme.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 20)
                        
                        Text(isSpanish ? "Soporte" : "Support")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(isSpanish ? "Estamos aquí para ayudarte" : "We're here to help you")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // WhatsApp Support
                    SupportCard(
                        icon: "message.fill",
                        title: "WhatsApp",
                        subtitle: isSpanish ? "Chatea con nosotros directamente" : "Chat with us directly",
                        color: SupportTheme.primary,
                        detail: SupportContact.whatsappNumber
                    ) {
                        openWhatsApp()
                    }
                    
                    // Telegram Support
                    SupportCard(
                        icon: "paperplane.fill",
                        title: "Telegram",
                        subtitle: isSpanish ? "Respuestas rápidas en Telegram" : "Fast responses on Telegram",
                        color: SupportTheme.secondary,
                        detail: "@\(SupportContact.telegramUsername)"
                    ) {
                        openTelegram()
                    }
                    
                    // Email Support
                    SupportCard(
                        icon: "envelope.fill",
                        title: isSpanish ? "Correo Electrónico" : "Email",
                        subtitle: isSpanish ? "Envíanos un correo" : "Send us an email",
                        color: SupportTheme.accent,
                        detail: SupportContact.email
                    ) {
                        openEmail()
                    }
                    
                    // Developer Info
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            
                            Text(isSpanish ? "Desarrollador" : "Developer")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(SupportContact.developerName)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(SupportTheme.primary)
                            
                            Text(SupportContact.whatsappNumber)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color(.secondarySystemBackground))
                                )
                                .onTapGesture {
                                    copyToClipboard(SupportContact.whatsappNumber)
                                }
                        }
                        .padding(.vertical, 12)
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .overlay(
            Group {
                if showCopiedAlert {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SupportTheme.primary)
                            
                            Text(isSpanish ? "¡Copiado al portapapeles!" : "Copied to clipboard!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.bottom, 50)
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
        let message = isSpanish ? "Hola, necesito ayuda con X" : "Hello, I need help with X"
        let urlString = "https://wa.me/\(number)?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTelegram() {
        let urlString = "https://t.me/\(SupportContact.telegramUsername)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openEmail() {
        let subject = isSpanish ? "Soporte X - Ayuda" : "X Support - Help"
        let urlString = "mailto:\(SupportContact.email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        
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
    let title: String
    let subtitle: String
    let color: Color
    let detail: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(color)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(SupportCardButtonStyle())
    }
}

// MARK: - Button Style
struct SupportCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    SupportView()
}
