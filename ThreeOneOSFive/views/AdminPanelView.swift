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
                
                Toggle(isOn: $adminSettings.tabSettings.bundleExplorerEnabled) {
                    HStack {
                        Image(systemName: "folder.badge.gearshape")
                            .foregroundStyle(adminSettings.tabSettings.bundleExplorerEnabled ? .green : .gray)
                        Text("Bundle Explorer")
                            .fontWeight(.medium)
                    }
                }
                .onChange(of: adminSettings.tabSettings.bundleExplorerEnabled) { _ in
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
    
    @EnvironmentObject var keyStore: KeyStore
    @State private var showRevokeAlert = false
    @State private var showManageSheet = false
    
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
                            .fill(statusColor.opacity(0.2))
                    )
                    .foregroundStyle(statusColor)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                keyDetail(icon: "clock.fill", text: "Duración: \(key.duration.displayName)")
                keyDetail(icon: "calendar", text: "Expira: \(key.expirationDateString)")
                keyDetail(icon: "hourglass", text: "Restante: \(key.timeRemaining)")
                
                if let userName = key.userName, !userName.isEmpty {
                    keyDetail(icon: "person.fill", text: "Usuario: \(userName)")
                }
                
                if key.isBanned, let reason = key.banReason {
                    keyDetail(icon: "xmark.shield.fill", text: "Razón ban: \(reason)")
                        .foregroundStyle(.red)
                }
                
                if !key.notifications.isEmpty {
                    keyDetail(icon: "bell.badge.fill", text: "\(key.notifications.count) notificación(es)")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            // Action buttons
            HStack(spacing: 8) {
                Button {
                    showManageSheet = true
                } label: {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Gestionar")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(role: .destructive) {
                    showRevokeAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Eliminar")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
        .alert("Eliminar Key", isPresented: $showRevokeAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                onRevoke()
            }
        } message: {
            Text("¿Estás seguro de que deseas eliminar esta Key? Esta acción no se puede deshacer.")
        }
        .sheet(isPresented: $showManageSheet) {
            KeyManagementSheet(key: key)
                .environmentObject(keyStore)
        }
    }
    
    private var statusColor: Color {
        switch key.status {
        case .active: return .green
        case .expired: return .red
        case .banned: return .orange
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


// MARK: - Key Management Sheet

struct KeyManagementSheet: View {
    let key: UserKey
    @EnvironmentObject var keyStore: KeyStore
    @Environment(\.dismiss) var dismiss
    
    @State private var showResetConfirm = false
    @State private var showAddTimeSheet = false
    @State private var showReduceTimeSheet = false
    @State private var showBanSheet = false
    @State private var daysToAdd = 1
    @State private var daysToReduce = 1
    @State private var banReason = ""
    
    var body: some View {
        NavigationView {
            List {
                // Key Info Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Key:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(key.keyString)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Estado:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(key.status.displayName)
                                .fontWeight(.medium)
                                .foregroundStyle(key.isBanned ? .orange : (key.isExpired ? .red : .green))
                        }
                        
                        HStack {
                            Text("Tiempo restante:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(key.timeRemaining)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Información")
                }
                
                // Time Management
                Section {
                    Button {
                        showResetConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Reset Key")
                            Spacer()
                            Text("Reiniciar tiempo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        showAddTimeSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                            Text("Añadir Tiempo")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Button {
                        showReduceTimeSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Reducir Tiempo")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Gestión de Tiempo")
                }
                
                // Ban Management
                Section {
                    if key.isBanned {
                        Button {
                            unbanKey()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(.green)
                                Text("Desbanear Key")
                                Spacer()
                            }
                        }
                        
                        if let reason = key.banReason {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Razón del ban:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(reason)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Button(role: .destructive) {
                            showBanSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "xmark.shield.fill")
                                Text("Banear Key")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } header: {
                    Text("Control de Acceso")
                }
                
                // Notifications
                if !key.notifications.isEmpty {
                    Section {
                        ForEach(Array(key.notifications.enumerated()), id: \.offset) { index, notification in
                            HStack(spacing: 12) {
                                Image(systemName: notification.icon)
                                    .foregroundStyle(colorForNotification(notification))
                                
                                Text(notification.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Button(role: .destructive) {
                            keyStore.clearNotifications(for: key)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Limpiar Notificaciones")
                            }
                        }
                    } header: {
                        Text("Notificaciones (\(key.notifications.count))")
                    }
                }
            }
            .navigationTitle("Gestionar Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Reset Key", isPresented: $showResetConfirm) {
            Button("Cancelar", role: .cancel) { }
            Button("Reset") {
                resetKey()
            }
        } message: {
            Text("Esto reiniciará el tiempo de expiración de la Key a su duración original.")
        }
        .sheet(isPresented: $showAddTimeSheet) {
            AddTimeSheet(days: $daysToAdd, onConfirm: {
                addTime()
            })
        }
        .sheet(isPresented: $showReduceTimeSheet) {
            ReduceTimeSheet(days: $daysToReduce, onConfirm: {
                reduceTime()
            })
        }
        .sheet(isPresented: $showBanSheet) {
            BanKeySheet(reason: $banReason, onConfirm: {
                banKey()
            })
        }
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
    
    private func resetKey() {
        keyStore.resetKey(key)
        dismiss()
    }
    
    private func addTime() {
        keyStore.addTime(to: key, days: daysToAdd)
        dismiss()
    }
    
    private func reduceTime() {
        keyStore.reduceTime(from: key, days: daysToReduce)
        dismiss()
    }
    
    private func banKey() {
        keyStore.banKey(key, reason: banReason.isEmpty ? nil : banReason)
        dismiss()
    }
    
    private func unbanKey() {
        keyStore.unbanKey(key)
        dismiss()
    }
}

// MARK: - Add Time Sheet

struct AddTimeSheet: View {
    @Binding var days: Int
    let onConfirm: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                    .padding(.top, 32)
                
                Text("Añadir Tiempo")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Text("Días a añadir:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Días", selection: $days) {
                        ForEach(1...365, id: \.self) { day in
                            Text("\(day) día(s)").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }
                
                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text("Añadir")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Reduce Time Sheet

struct ReduceTimeSheet: View {
    @Binding var days: Int
    let onConfirm: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                    .padding(.top, 32)
                
                Text("Reducir Tiempo")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Text("Días a reducir:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Días", selection: $days) {
                        ForEach(1...365, id: \.self) { day in
                            Text("\(day) día(s)").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }
                
                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text("Reducir")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Ban Key Sheet

struct BanKeySheet: View {
    @Binding var reason: String
    let onConfirm: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "xmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                    .padding(.top, 32)
                
                Text("Banear Key")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Esta Key será bloqueada y el usuario no podrá acceder a Free Fire")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Razón (opcional):")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Violación de términos, comportamiento sospechoso...", text: $reason, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                }
                .padding(.horizontal, 24)
                
                Button(role: .destructive) {
                    onConfirm()
                    dismiss()
                } label: {
                    Text("Banear")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
