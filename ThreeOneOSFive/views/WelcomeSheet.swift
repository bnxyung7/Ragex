import SwiftUI

struct WelcomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.15), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App icon and title
                        VStack(spacing: 16) {
                            if let appIcon = UIImage(named: "AppIcon60x60") {
                                Image(uiImage: appIcon)
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(18)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.accentColor)
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        Text("X")
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                            }
                            
                            VStack(spacing: 4) {
                                Text("Bienvenido a X")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Personaliza tu experiencia Free Fire")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 32)
                        
                        // Important notice
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Certificado Requerido")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("X solo funciona con certificado enterprise. Otros métodos no son soportados.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Community section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ÚNETE A LA COMUNIDAD")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                SocialLinkButton(
                                    icon: "discord",
                                    title: "Discord",
                                    subtitle: "Únete al servidor oficial",
                                    color: .purple,
                                    url: "https://discord.gg/AksKwSWaKq"
                                )
                                
                                SocialLinkButton(
                                    icon: "whatsapp",
                                    title: "Grupo WhatsApp",
                                    subtitle: "Chatea con la comunidad",
                                    color: .green,
                                    url: "https://chat.whatsapp.com/LMi0ORfWlDd6iDl0CIvryM"
                                )
                                
                                SocialLinkButton(
                                    icon: "whatsapp",
                                    title: "Canal WhatsApp",
                                    subtitle: "Recibe actualizaciones",
                                    color: .green,
                                    url: "https://whatsapp.com/channel/0029Vb8Pvbk0QeaiLOyydq1w"
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Credits
                        VStack(spacing: 8) {
                            Text("CRÉDITOS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                            
                            Text("Desarrollado por la comunidad X")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            
                            Text("Gracias por ser parte de nosotros")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Continuar")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            // Play welcome sound only once
            SoundPlayer.shared.playWelcome()
        }
    }
}

struct SocialLinkButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let url: String
    
    var body: some View {
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    if icon == "discord" {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.title3)
                            .foregroundStyle(color)
                    } else {
                        Image(systemName: "message.fill")
                            .font(.title3)
                            .foregroundStyle(color)
                    }
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}
