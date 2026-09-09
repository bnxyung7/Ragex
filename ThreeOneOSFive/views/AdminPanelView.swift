import SwiftUI

struct AdminPanelView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var keyStore: KeyStore
    @EnvironmentObject var adminSettings: AdminSettings
    
    @State private var showCreateKey = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Tab Controls
                tabControlsView
                    .tabItem {
                        Label("Tabs", systemImage: "square.grid.2x2")
                    }
                    .tag(0)
                
                // Key Management
                keyManagementView
                    .tabItem {
                        Label("Keys", systemImage: "key.fill")
                    }
                    .tag(1)
            }
            .navigationTitle("Panel Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateKey) {
            CreateKeyView(isPresented: $showCreateKey)
                .environmentObject(keyStore)
        }
    }
    
    // MARK: - Tab Controls View
    
    private var tabControlsView: some View {
        List {
            Section {
                Toggle(isOn: $adminSettings.tabSettings.patchesEnabled) {
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundStyle(adminSettings.tabSettings.patchesEnabled ? .green : .gray)
                        Text("Patches")
                            .fontWeight(.medium)
                    }
                }
                .onChange(of: adminSettings.tabSettings.patchesEnabled) { _ in
                    adminSettings.saveTabSettings()
                }
                
                Toggle(isOn: $adminSettings.tabSettings.filesEnabled) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(adminSettings.tabSettings.filesEnabled ? .green : .gray)
                        Text("Files")
                            .fontWeight(.medium)
                    }
                }
                .onChange(of: adminSettings.tabSettings.filesEnabled) { _ in
                    adminSettings.saveTabSettings()
                }
                
                Toggle(isOn: $adminSettings.tabSettings.freeFireEnabled) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(adminSettings.tabSettings.freeFireEnabled ? .green : .gray)
                        Text("Free Fire")
                            .fontWeight(.medium)
                    }
                }
                .onChange(of: adminSettings.tabSettings.freeFireEnabled) { _ in
                    adminSettings.saveTabSettings()
                }
                
            } header: {
                Text("Control de Pestañas")
            } footer: {
                Text("Activa o desactiva las pestañas que serán visibles en la aplicación. Los cambios se aplican inmediatamente.")
            }
            
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Patches")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(adminSettings.tabSettings.patchesEnabled ? "Visible" : "Oculto")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(adminSettings.tabSettings.patchesEnabled ? .green : .red)
                    }
                    Spacer()
                    Image(systemName: adminSettings.tabSettings.patchesEnabled ? "eye.fill" : "eye.slash.fill")
                        .foregroundStyle(adminSettings.tabSettings.patchesEnabled ? .green : .red)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Files")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(adminSettings.tabSettings.filesEnabled ? "Visible" : "Oculto")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(adminSettings.tabSettings.filesEnabled ? .green : .red)
                    }
                    Spacer()
                    Image(systemName: adminSettings.tabSettings.filesEnabled ? "eye.fill" : "eye.slash.fill")
                        .foregroundStyle(adminSettings.tabSettings.filesEnabled ? .green : .red)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Free Fire")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(adminSettings.tabSettings.freeFireEnabled ? "Visible" : "Oculto")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(adminSettings.tabSettings.freeFireEnabled ? .green : .red)
                    }
                    Spacer()
                    Image(systemName: adminSettings.tabSettings.freeFireEnabled ? "eye.fill" : "eye.slash.fill")
                        .foregroundStyle(adminSettings.tabSettings.freeFireEnabled ? .green : .red)
                }
            } header: {
                Text("Estado Actual")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Key Management View
    
    private var keyManagementView: some View {
        List {
            // Create Key Button
            Section {
                Button {
                    showCreateKey = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                        Text("Crear Nueva Key")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            }
            
            // Active Keys
            if !keyStore.activeKeys.isEmpty {
                Section {
                    ForEach(keyStore.activeKeys) { key in
                        KeyRowView(key: key, onRevoke: {
                            keyStore.revokeKey(key)
                        })
                    }
                } header: {
                    HStack {
                        Text("Keys Activas")
                        Spacer()
                        Text("\(keyStore.activeKeys.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Expired Keys
            if !keyStore.expiredKeys.isEmpty {
                Section {
                    ForEach(keyStore.expiredKeys) { key in
                        KeyRowView(key: key, onRevoke: {
                            keyStore.revokeKey(key)
                        })
                    }
                } header: {
                    HStack {
                        Text("Keys Expiradas")
                        Spacer()
                        Text("\(keyStore.expiredKeys.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Empty state
            if keyStore.allKeys.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "key.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        
                        Text("No hay Keys creadas")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Crea tu primera Key para empezar")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Key Row View

struct KeyRowView: View {
    let key: UserKey
    let onRevoke: () -> Void
    
    @State private var showRevokeAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Key string
            HStack {
                Text(key.keyString)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Status badge
                Text(key.status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(key.isExpired ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                    )
                    .foregroundStyle(key.isExpired ? .red : .green)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                keyDetail(icon: "clock.fill", text: "Duración: \(key.duration.displayName)")
                keyDetail(icon: "calendar", text: "Expira: \(key.expirationDateString)")
                keyDetail(icon: "hourglass", text: "Restante: \(key.timeRemaining)")
                
                if let userName = key.userName, !userName.isEmpty {
                    keyDetail(icon: "person.fill", text: "Usuario: \(userName)")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            // Revoke button
            Button(role: .destructive) {
                showRevokeAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Revocar Key")
                }
                .font(.caption)
                .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
        .alert("Revocar Key", isPresented: $showRevokeAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Revocar", role: .destructive) {
                onRevoke()
            }
        } message: {
            Text("¿Estás seguro de que deseas revocar esta Key? Esta acción no se puede deshacer.")
        }
    }
    
    private func keyDetail(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .frame(width: 14)
            Text(text)
        }
    }
}

// MARK: - Create Key View

struct CreateKeyView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var keyStore: KeyStore
    
    @State private var selectedDuration: KeyDuration = .oneDay
    @State private var userName: String = ""
    @State private var createdKey: UserKey?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let key = createdKey {
                    // Key created - show result
                    keyCreatedView(key: key)
                } else {
                    // Create form
                    createFormView
                }
            }
            .navigationTitle("Crear Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private var createFormView: some View {
        List {
            Section {
                Picker("Duración", selection: $selectedDuration) {
                    ForEach(KeyDuration.allCases, id: \.self) { duration in
                        Text(duration.displayName).tag(duration)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Duración de la Key")
            } footer: {
                Text("Selecciona cuánto tiempo será válida la Key")
            }
            
            Section {
                TextField("Nombre del usuario (opcional)", text: $userName)
                    .textInputAutocapitalization(.words)
            } header: {
                Text("Usuario")
            } footer: {
                Text("Asigna la Key a un usuario específico")
            }
            
            Section {
                Button {
                    createKey()
                } label: {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("Generar Key")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func keyCreatedView(key: UserKey) -> some View {
        VStack(spacing: 24) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
                .padding(.top, 32)
            
            Text("Key Creada Exitosamente")
                .font(.title2)
                .fontWeight(.bold)
            
            // Key display
            VStack(alignment: .leading, spacing: 12) {
                Text("Key generada:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text(key.keyString)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                
                // Copy button
                Button {
                    UIPasteboard.general.string = key.keyString
                    
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copiar Key")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            
            // Details
            VStack(spacing: 8) {
                keyDetailRow(label: "Duración", value: key.duration.displayName)
                keyDetailRow(label: "Expira", value: key.expirationDateString)
                
                if let userName = key.userName, !userName.isEmpty {
                    keyDetailRow(label: "Usuario", value: userName)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Done button
            Button {
                isPresented = false
            } label: {
                Text("Listo")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.accent)
                    )
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    private func keyDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private func createKey() {
        let userNameValue = userName.isEmpty ? nil : userName
        let key = keyStore.createKey(duration: selectedDuration, userName: userNameValue)
        
        withAnimation {
            createdKey = key
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// Extension to save tab settings
extension AdminSettings {
    func saveTabSettings() {
        if let encoded = try? JSONEncoder().encode(tabSettings) {
            UserDefaults.standard.set(encoded, forKey: "com.x.tabSettings")
        }
    }
}
