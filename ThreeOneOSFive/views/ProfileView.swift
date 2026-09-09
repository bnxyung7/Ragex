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
    
    var body: some View {
        NavigationView {
            List {
                // Key Status Section
                keyStatusSection
                
                // Key Activation Section
                if keyStore.activeSession == nil {
                    keyActivationSection
                }
                
                // Admin Access Section
                adminSection
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
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
    
    // MARK: - Key Status Section
    
    private var keyStatusSection: some View {
        Section {
            if let session = keyStore.activeSession {
                // Active key info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Free Fire Activo")
                                .font(.headline)
                            Text("Tu Key está activa")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Key details
                    keyDetailRow(icon: "key.fill", label: "Key", value: session.key.keyString)
                    keyDetailRow(icon: "clock.fill", label: "Tiempo restante", value: session.key.timeRemaining)
                    keyDetailRow(icon: "calendar", label: "Expira", value: session.key.expirationDateString)
                    keyDetailRow(icon: "checkmark.seal.fill", label: "Estado", value: session.key.status.displayName)
                    
                    if let userName = session.key.userName {
                        keyDetailRow(icon: "person.fill", label: "Usuario", value: userName)
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
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(.vertical, 8)
                
            } else {
                // No active key
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Free Fire Bloqueado")
                                .font(.headline)
                            Text("Necesitas activar una Key")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text("Tienes que activar una Key en Perfil para usar Free Fire.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Estado de Free Fire")
        }
    }
    
    // MARK: - Key Activation Section
    
    private var keyActivationSection: some View {
        Section {
            Button {
                showKeyActivation = true
            } label: {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text("Activar Key")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if let error = activationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Activación")
        } footer: {
            Text("Introduce tu Key en formato: JUSTINRAGEX-XXX-XXX")
        }
    }
    
    // MARK: - Admin Section
    
    private var adminSection: some View {
        Section {
            if adminSettings.isAdminAuthenticated {
                // Admin is logged in
                Button {
                    showAdminPanel = true
                } label: {
                    HStack {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundStyle(.purple)
                        Text("Panel de Administración")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Button(role: .destructive) {
                    adminSettings.logout()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Cerrar sesión Admin")
                    }
                }
            } else {
                // Admin login button
                Button {
                    showAdminLogin = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.key.fill")
                            .foregroundStyle(.blue)
                        Text("Acceso Administrador")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } header: {
            Text("Administración")
        }
    }
    
    // MARK: - Helper Views
    
    private func keyDetailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Actions
    
    private func activateKey() {
        activationError = nil
        
        let result = keyStore.activateKey(keyInput)
        
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

// MARK: - Key Activation Sheet

struct KeyActivationSheet: View {
    @Binding var isPresented: Bool
    @Binding var keyInput: String
    let onActivate: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.top, 32)
                
                // Title
                Text("Activar Key")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Introduce tu Key de Free Fire")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Input field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    TextField("JUSTINRAGEX-XXX-XXX", text: $keyInput)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .font(.system(.body, design: .monospaced))
                }
                .padding(.horizontal, 24)
                
                // Activate button
                Button {
                    onActivate()
                } label: {
                    Text("Activar")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(keyInput.isEmpty ? Color.gray.opacity(0.3) : AppTheme.accent)
                        )
                        .foregroundStyle(.white)
                }
                .disabled(keyInput.isEmpty)
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isPresented = false
                    }
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
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 32)
                
                // Title
                Text("Acceso Administrador")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Introduce las credenciales de administrador")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Input fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Usuario")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        TextField("Usuario", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.characters)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contraseña")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        SecureField("Contraseña", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal, 24)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                }
                
                // Login button
                Button {
                    attemptLogin()
                } label: {
                    Text("Iniciar Sesión")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(username.isEmpty || password.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        )
                        .foregroundStyle(.white)
                }
                .disabled(username.isEmpty || password.isEmpty)
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isPresented = false
                    }
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
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}
