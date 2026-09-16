import SwiftUI

struct ProfileView: View {
    @Environment(\.appLanguage) private var language
    @StateObject private var keyStore = KeyStore.shared
    @StateObject private var adminSettings = AdminSettings.shared
    
    @State private var showAdminLogin = false
    @State private var showAdminPanel = false
    @State private var showKeyActivation = false
    @State private var keyInput = ""
    @State private var activationError: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "08080C").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Key Status Section
                        keyStatusCard
                        
                        // Key Activation Section
                        if keyStore.activeSession == nil {
                            keyActivationCard
                        }
                        
                        // Admin Access Section
                        adminCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "08080C"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showAdminLogin) {
            AdminLoginView(isPresented: $showAdminLogin, onSuccess: {
                showAdminPanel = true
            })
        }
        .sheet(isPresented: $showAdminPanel) {
            AdminPanelView(isPresented: $showAdminPanel)
                .environmentObject(keyStore)
                .environmentObject(adminSettings)
        }
        .sheet(isPresented: $showKeyActivation) {
            KeyActivationSheet(
                isPresented: $showKeyActivation,
                keyInput: $keyInput,
                onActivate: activateKey
            )
        }
    }
    
    // MARK: - Key Status Card
    
    private var keyStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let session = keyStore.activeSession {
                // Active key VIP card
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill((session.key.isBanned ? Color(hex: "EF4444") : Color(hex: "10B981")).opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: session.key.isBanned ? "xmark.octagon.fill" : "checkmark.seal.fill")
                            .foregroundStyle(session.key.isBanned ? Color(hex: "EF4444") : Color(hex: "10B981"))
                            .font(.system(size: 22))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.key.isBanned ? "ACCESO BANEADO" : "MEMBRESÃA ACTIVA")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(session.key.isBanned ? Color(hex: "EF4444") : .white)
                        Text(session.key.isBanned ? "Clave suspendida por administraciÃ³n" : "Acceso verificado a Project X")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                    }
                    
                    Spacer()
                    
                    CyberBadge(
                        text: session.key.isBanned ? "BANEADO" : "PRO",
                        color: session.key.isBanned ? Color(hex: "EF4444") : AppTheme.accent
                    )
                }
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Key details
                VStack(spacing: 10) {
                    keyDetailRow(icon: "key.fill", label: "Clave", value: session.key.keyString, copyable: true)
                    keyDetailRow(icon: "clock.fill", label: "Tiempo restante", value: session.key.timeRemaining)
                    keyDetailRow(icon: "calendar", label: "Fecha expiraciÃ³n", value: session.key.expirationDateString)
                    keyDetailRow(icon: "checkmark.shield.fill", label: "Estado", value: session.key.status.displayName)
                    
                    if let userName = session.key.userName {
                        keyDetailRow(icon: "person.fill", label: "Usuario asignado", value: userName)
                    }
                }
                
                if session.key.isBanned, let reason = session.key.banReason {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Motivo de suspensiÃ³n:")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                        Text(reason)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: "EF4444"))
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "EF4444").opacity(0.1))
                    )
                }
                
                // Deactivate button
                Button(role: .destructive) {
                    withAnimation {
                        keyStore.deactivateSession()
                    }
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Desactivar Key")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(Color(hex: "EF4444"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "EF4444").opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "EF4444").opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                .padding(.top, 4)
            } else {
                // Inactive state
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(AppTheme.accent)
                            .font(.system(size: 26))
                    }
                    
                    VStack(spacing: 4) {
                        Text("Sin MembresÃ­a Activa")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Activa tu clave de acceso para desbloquear todas las funciones de Project X")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
        }
        .padding(16)
        .obsidianCard(cornerRadius: 18, borderColor: keyStore.activeSession != nil ? AppTheme.accent.opacity(0.3) : AppTheme.cardBorder, glowing: keyStore.activeSession != nil)
    }
    
    // MARK: - Key Activation Card
    
    private var keyActivationCard: some View {
        Button {
            showKeyActivation = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "key.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Activar Nueva Clave")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Introduce tu cÃ³digo de acceso")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "94A3B8"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "94A3B8"))
            }
            .padding(16)
            .obsidianCard(cornerRadius: 16, borderColor: AppTheme.accent.opacity(0.2))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Admin Card
    
    private var adminCard: some View {
        VStack(spacing: 10) {
            if adminSettings.isAdminAuthenticated {
                Button {
                    showAdminPanel = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "8B5CF6").opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6"))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Panel de AdministraciÃ³n")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Gestor de claves y configuraciÃ³n")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "94A3B8"))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: "94A3B8"))
                    }
                    .padding(16)
                    .obsidianCard(cornerRadius: 16, borderColor: Color(hex: "8B5CF6").opacity(0.3))
                }
                .buttonStyle(.plain)
                
                Button(role: .destructive) {
                    adminSettings.logout()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Cerrar SesiÃ³n Administrador")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color(hex: "EF4444"))
                    .padding(.vertical, 8)
                }
            } else {
                Button {
                    showAdminLogin = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "94A3B8"))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Acceso Administrador")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("GestiÃ³n de seguridad")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "94A3B8"))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color(hex: "94A3B8"))
                    }
                    .padding(14)
                    .obsidianCard(cornerRadius: 14, borderColor: Color.white.opacity(0.06))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func keyDetailRow(icon: String, label: String, value: String, copyable: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "94A3B8"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
            
            if copyable {
                Button {
                    UIPasteboard.general.string = value
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func colorForNotification(_ notification: KeyNotification) -> Color {
        switch notification.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        default: return .gray
        }
    }
    
    // MARK: - Actions
    
    private func activateKey() {
        activationError = nil
        isLoading = true
        
        keyStore.activateKey(keyInput) { result in
            isLoading = false
            
            switch result {
            case .success:
                withAnimation {
                    showKeyActivation = false
                    keyInput = ""
                }
                
                // Play activation sound
                SoundPlayer.shared.playActivate()
                
            case .failure(let error):
                activationError = error.localizedDescription
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
}

// MARK: - Key Activation Sheet

struct KeyActivationSheet: View {
    @Binding var isPresented: Bool
    @Binding var keyInput: String
    let onActivate: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "08080C").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "key.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.top, 24)
                    
                    VStack(spacing: 6) {
                        Text("Activar MembresÃ­a")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Introduce tu clave asignada para activar el acceso")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CLAVE DE ACCESO")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "94A3B8"))
                        
                        TextField("Ej: PRO-KEY-XXXX o PERSONALIZADA", text: $keyInput)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: "131420"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    Button {
                        onActivate()
                    } label: {
                        Text("Activar Clave")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(keyInput.isEmpty ? Color.white.opacity(0.1) : AppTheme.accent)
                            )
                            .foregroundStyle(keyInput.isEmpty ? Color(hex: "94A3B8") : .white)
                    }
                    .disabled(keyInput.isEmpty)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "08080C"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Admin Login View

struct AdminLoginView: View {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    
    @StateObject private var adminSettings = AdminSettings.shared
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "08080C").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "8B5CF6").opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(hex: "8B5CF6"))
                    }
                    .padding(.top, 24)
                    
                    VStack(spacing: 6) {
                        Text("Acceso Administrador")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Introduce credenciales autorizadas")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                    }
                    
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("USUARIO")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "94A3B8"))
                            
                            TextField("Usuario", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "131420"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CONTRASEÃ‘A")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "94A3B8"))
                            
                            SecureField("ContraseÃ±a", text: $password)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "131420"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color(hex: "EF4444"))
                            .padding(.horizontal, 24)
                    }
                    
                    Button {
                        attemptLogin()
                    } label: {
                        Text("Entrar al Panel")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(username.isEmpty || password.isEmpty ? Color.white.opacity(0.1) : Color(hex: "8B5CF6"))
                            )
                            .foregroundStyle(username.isEmpty || password.isEmpty ? Color(hex: "94A3B8") : .white)
                    }
                    .disabled(username.isEmpty || password.isEmpty)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "08080C"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func attemptLogin() {
        errorMessage = nil
        
        if adminSettings.authenticate(username: username, password: password) {
            isPresented = false
            onSuccess()
        } else {
            errorMessage = "Credenciales incorrectas"
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}