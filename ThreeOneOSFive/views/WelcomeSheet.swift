import SwiftUI

struct WelcomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    let totalPages = 4
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentPage ? AppTheme.accent : Color.white.opacity(0.12))
                            .frame(height: 4)
                            .frame(maxWidth: index == currentPage ? 36 : 16)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 24)
                
                Text("Paso \(currentPage + 1) de \(totalPages)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(hex: "94A3B8"))
                    .padding(.top, 8)
                
                // Content
                TabView(selection: $currentPage) {
                    Page1View().tag(0)
                    Page2View().tag(1)
                    Page3View().tag(2)
                    Page4View().tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Next button
                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation(.spring(response: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage < totalPages - 1 ? "Siguiente" : "Comenzar")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.accent)
                    )
                    .shadow(color: AppTheme.accent.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .interactiveDismissDisabled()
    }
}

// Page 1: Welcome
struct Page1View: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.18))
                    .frame(width: 120, height: 120)
                    .blur(radius: 12)
                
                AppLogo(size: 80)
            }
            
            VStack(spacing: 10) {
                CyberBadge(text: "iOS", color: .white)
                
                Text("Bienvenido a la plataforma más potente y avanzada para iOS.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "94A3B8"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// Page 2: Certificate Warning
struct Page2View: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(hex: "F59E0B").opacity(0.15))
                    .frame(width: 110, height: 110)
                
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 52))
                    .foregroundStyle(Color(hex: "F59E0B"))
            }
            
            VStack(spacing: 10) {
                Text("Compatibilidad Enterprise")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Diseñado para funcionar directamente en tu dispositivo con la máxima estabilidad.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "94A3B8"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// Page 3: Community Links
struct Page3View: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("Canales Oficiales")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Mantente informado de las últimas actualizaciones")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "94A3B8"))
            }
            
            VStack(spacing: 12) {
                CommunityButton(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Discord Soporte",
                    subtitle: "Atención personalizada",
                    color: Color(hex: "5865F2"),
                    url: SupportContact.discordSupportURL
                )
                
                CommunityButton(
                    icon: "megaphone.fill",
                    title: "Discord Anuncio",
                    subtitle: "Actualizaciones y descargas",
                    color: AppTheme.accent,
                    url: SupportContact.discordAnnounceURL
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// Page 4: Credits
struct Page4View: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(hex: "8B5CF6").opacity(0.18))
                    .frame(width: 110, height: 110)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color(hex: "8B5CF6"))
            }
            
            VStack(spacing: 10) {
                Text("Desarrollo y Soporte")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Creado y optimizado por Bnxyung7.\nDisfruta de la mejor experiencia para iOS.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "94A3B8"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

struct CommunityButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "94A3B8"))
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "94A3B8"))
            }
            .padding(14)
            .obsidianCard(cornerRadius: 16, borderColor: color.opacity(0.25))
        }
    }
}