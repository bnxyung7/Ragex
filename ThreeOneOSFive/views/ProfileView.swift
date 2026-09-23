import SwiftUI

struct ProfileView: View {
    @Environment(\.appLanguage) private var language
    @StateObject private var keyStore = KeyStore.shared
    @StateObject private var adminSettings = AdminSettings.shared
    @StateObject private var pushService = PushNotificationService.shared
    @StateObject private var notificationService = NotificationService.shared

    @State private var showAdminLogin = false
    @State private var showAdminPanel = false
    @State private var showKeyActivation = false
    @State private var showNotificationsSheet = false
    @State private var keyInput = ""
    @State private var activationError: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.sectionSpacing) {
                        // Key Status Section
                        keyStatusCard
                        
                        // Key Activation Section
                        if keyStore.activeSession == nil {
                            keyActivationCard
                        }
                        
                        // Admin Access Section
                        adminCard
                    }
                    .padding(.horizontal, AppTheme.pageInset)
                    .padding(.top, AppTheme.spacing16)
                    .padding(.bottom, AppTheme.spacing32)
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNotificationsSheet = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                            if notificationService.unreadCount > 0 {
                                Circle()
                                    .fill(Color(hex: "EF4444"))
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsCenterView()
            }
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
                activationError: $activationError,
                isLoading: $isLoading,
                onActivate: activateKey
            )
        }
    }
    
    // MARK: - Push permission row

    @ViewBuilder
    private var pushPermissionRow: some View {
        HStack(spacing: AppTheme.spacing10) {
            Image(systemName: pushService.permissionGranted ? "bell.fill" : "bell.slash.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(pushService.permissionGranted ? Color(hex: "10B981") : Color(hex: "F59E0B"))
                .frame(width: 20)

            Text("Notificaciones Push")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "94A3B8"))

            Spacer()

            if pushService.permissionGranted {
                Text("Activas")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "10B981"))
            } else if pushService.permissionDetermined {
                Button {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Activar")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.spacing10)
                        .padding(.vertical, AppTheme.spacing4)
                        .background(Color(hex: "F59E0B"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Text("Pendiente")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "94A3B8"))
            }
        }
        .padding(.vertical, AppTheme.spacing4)
    }

    // MARK: - Key Status Card
    
    private var keyStatusCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            if let session = keyStore.activeSession {
                // Active or Expired key card
                let isExp = session.key.isExpired
                let isBan = session.key.isBanned
                let statusColor: Color = isBan ? Color(hex: "EF4444") : (isExp ? Color(hex: "F59E0B") : Color(hex: "10B981"))
                
                HStack(spacing: AppTheme.spacing12) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: isBan ? "xmark.octagon.fill" : (isExp ? "exclamationmark.triangle.fill" : "checkmark.seal.fill"))
                            .foregroundStyle(statusColor)
                            .font(.system(size: 22))
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                        Text(isBan ? "ACCESO BANEADO" : (isExp ? "MEMBRESÍA EXPIRADA" : "MEMBRESÍA ACTIVA"))
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(isBan ? Color(hex: "EF4444") : (isExp ? Color(hex: "F59E0B") : .white))
                        Text(isBan ? "Clave suspendida por administración" : (isExp ? "Pestañas de juego deshabilitadas" : "Acceso verificado a X"))
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                    }
                    
                    Spacer()
                    
                    CyberBadge(
                        text: isBan ? "BANEADO" : (isExp ? "EXPIRADO" : "PRO"),
                        color: statusColor
                    )
                }
                
                if isExp {
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("⚠️ Tu clave ha vencido")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "F59E0B"))
                        Text("Tu sesión sigue guardada. Renueva tu clave o activa una nueva para habilitar la pestaña Free Fire.")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: "CBD5E1"))
                            .lineSpacing(2)
                        
                        Link(destination: URL(string: "https://wa.me/18099289722?text=Hola,%20mi%20clave%20de%20Project%20X%20expiró%20y%20deseo%20renovarla:\(session.key.keyString)")!) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text("Renovar Clave por WhatsApp")
                                    .fontWeight(.bold)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppTheme.spacing12)
                            .padding(.vertical, AppTheme.spacing8)
                            .background(Color(hex: "10B981"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.top, AppTheme.spacing4)
                    }
                    .padding(AppTheme.spacing12)
                    .background(Color(hex: "F59E0B").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Key details
                VStack(spacing: AppTheme.spacing6) {
                    keyDetailRow(icon: "key.fill", label: "Clave", value: session.key.keyString, copyable: true)
                    Divider().background(Color.white.opacity(0.05))
                    keyDetailRow(icon: "clock.fill", label: "Tiempo restante", value: session.key.timeRemaining)
                    Divider().background(Color.white.opacity(0.05))
                    keyDetailRow(icon: "calendar", label: "Fecha expiración", value: session.key.expirationDateString)
                    Divider().background(Color.white.opacity(0.05))
                    keyDetailRow(icon: "checkmark.shield.fill", label: "Estado", value: session.key.status.displayName)
                    
                    if let userName = session.key.userName {
                        Divider().background(Color.white.opacity(0.05))
                        keyDetailRow(icon: "person.fill", label: "Usuario asignado", value: userName)
                    }

                    Divider().background(Color.white.opacity(0.05))
                    pushPermissionRow
                }
                
                if session.key.isBanned, let reason = session.key.banReason {
                    VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                        Text("Motivo de suspensión:")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                        Text(reason)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: "EF4444"))
                    }
                    .padding(AppTheme.spacing12)
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
                    .padding(.vertical, AppTheme.spacing12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "EF4444").opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "EF4444").opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                .padding(.top, AppTheme.spacing6)
            } else {
                // Inactive state
                VStack(spacing: AppTheme.spacing12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(AppTheme.accent)
                            .font(.system(size: 26))
                    }
                    
                    VStack(spacing: AppTheme.spacing6) {
                        Text("Sin Membresía Activa")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Activa tu clave de acceso para desbloquear todas las funciones de X")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.spacing12)
            }
        }
        .padding(AppTheme.cardPadding)
        .obsidianCard(cornerRadius: 18, borderColor: keyStore.activeSession != nil ? AppTheme.accent.opacity(0.3) : AppTheme.cardBorder, glowing: keyStore.activeSession != nil)
    }
    
    // MARK: - Key Activation Card
    
    private var keyActivationCard: some View {
        Button {
            showKeyActivation = true
        } label: {
            HStack(spacing: AppTheme.spacing12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "key.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    Text("Activar Nueva Clave")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Introduce tu código de acceso")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "94A3B8"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "94A3B8"))
            }
            .padding(AppTheme.cardPadding)
            .obsidianCard(cornerRadius: 16, borderColor: AppTheme.accent.opacity(0.2))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Admin Card
    
    private var adminCard: some View {
        VStack(spacing: AppTheme.spacing12) {
            if adminSettings.isAdminAuthenticated {
                Button {
                    showAdminPanel = true
                } label: {
                    HStack(spacing: AppTheme.spacing12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "8B5CF6").opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6"))
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                            Text("Panel de Administración")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Gestor de claves y configuración")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "94A3B8"))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: "94A3B8"))
                    }
                    .padding(AppTheme.cardPadding)
                    .obsidianCard(cornerRadius: 16, borderColor: Color(hex: "8B5CF6").opacity(0.3))
                }
                .buttonStyle(.plain)
                
                Button(role: .destructive) {
                    adminSettings.logout()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Cerrar Sesión Administrador")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color(hex: "EF4444"))
                    .padding(.vertical, AppTheme.spacing8)
                }
            } else {
                Button {
                    showAdminLogin = true
                } label: {
                    HStack(spacing: AppTheme.spacing12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "94A3B8"))
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                            Text("Acceso Administrador")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Gestión de seguridad")
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
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 22)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "94A3B8"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
            
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
        .padding(.vertical, AppTheme.spacing6)
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
    @Binding var activationError: String?
    @Binding var isLoading: Bool
    let onActivate: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: "key.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 6) {
                        Text("Activar Membresía")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Introduce tu clave asignada para activar el acceso")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "94A3B8"))
                            .multilineTextAlignment(.center)
                    }
                    
                    if let error = activationError {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ACCESO DENEGADO")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(Color(hex: "FECACA"))
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "EF4444").opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(hex: "EF4444").opacity(0.35), lineWidth: 1))
                        .padding(.horizontal, 24)
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
                                    .fill(Color(hex: "0E0E0E"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    Button {
                        onActivate()
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(0.9)
                            }
                            Text(isLoading ? "Verificando..." : "Activar Clave")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.1) : Color.white)
                        )
                        .foregroundStyle(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(hex: "94A3B8") : Color.black)
                    }
                    .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
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
                            Text("CONTRASEÑA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "94A3B8"))
                            
                            SecureField("Contraseña", text: $password)
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
