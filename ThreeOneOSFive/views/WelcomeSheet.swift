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
                            .fill(index <= currentPage ? Color.orange : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .frame(maxWidth: index == currentPage ? 40 : 20)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                Text("Step \(currentPage + 1) of \(totalPages)")
                    .font(.caption)
                    .foregroundStyle(.gray)
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
                    HStack {
                        Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled()
    }
}

// Page 1: Welcome
struct Page1View: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Text("X")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 16) {
                Text("Bienvenido a X")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Personaliza tu experiencia Free Fire con patches exclusivos")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// Page 2: Certificate Warning
struct Page2View: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Warning icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
            }
            
            VStack(spacing: 16) {
                Text("Certificado Requerido")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("X solo funciona cuando está firmado con un certificado enterprise. Otros métodos de instalación no son soportados.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
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
            
            VStack(spacing: 16) {
                Text("Únete a la Comunidad")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Conéctate con otros usuarios")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            VStack(spacing: 12) {
                CommunityButton(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Discord",
                    subtitle: "Servidor oficial",
                    color: .purple,
                    url: "https://discord.gg/AksKwSWaKq"
                )
                
                CommunityButton(
                    icon: "megaphone.fill",
                    title: "Canal WhatsApp",
                    subtitle: "Actualizaciones oficiales",
                    color: .green,
                    url: "https://whatsapp.com/channel/0029Vb7NRaRAojYuOAfX5S0S"
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
        VStack(spacing: 32) {
            Spacer()
            
            // Credits icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
            }
            
            VStack(spacing: 16) {
                Text("Créditos")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                VStack(spacing: 12) {
                    Text("Desarrollador")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    
                    Text("Bnxyung7")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    
                    // Contact button
                    Button {
                        if let url = URL(string: "tel:+18099289722") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                            Text("+1 (809) 928-9722")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Text("Gracias por usar X")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.top, 8)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
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
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
    }
}
