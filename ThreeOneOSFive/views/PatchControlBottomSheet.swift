import SwiftUI

struct PatchControlBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var patchStore: PatchProjectStore
    
    let patch: BundlePatch
    
    @State private var isApplying = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Check if patch is under maintenance (OTHERS category)
    private var isUnderMaintenance: Bool {
        return patch.category == .others
    }
    
    private var patchProject: PatchProject? {
        let items = patchStore.items
        guard let item = items.first(where: {
            $0.packageURL.lastPathComponent == patch.url.lastPathComponent
        }) else { return nil }
        return item.project
    }
    
    private var receipt: PatchTransactionReceipt? {
        guard let project = patchProject else { return nil }
        return DevicePatchService.latestReceipt(projectID: project.id)
    }
    
    private var isActive: Bool {
        receipt != nil
    }
    
    var body: some View {
        ZStack {
            // Dark background like the app
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                // Status banner (if active)
                if isActive {
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OPCIÓN ACTIVADA")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Text(patch.displayName.uppercased())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                
                // Patch title
                VStack(spacing: 8) {
                    Text(patch.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    if !isActive && !isUnderMaintenance {
                        Text("Listo para activar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, isActive ? 16 : 24)
                .padding(.horizontal, 20)
                
                // Maintenance message for OTHERS
                if isUnderMaintenance {
                    VStack(spacing: 16) {
                        Text("Mantenimiento")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .padding(.top, 32)
                        
                        Text("Esta opción no está disponible en este momento.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 32)
                    
                    Spacer()
                    
                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                            Text("CERRAR")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.gray)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    
                } else {
                    // Normal activation controls
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 12) {
                    // ACTIVAR button
                    Button {
                        if !isActive && !isApplying && !isRestoring {
                            activatePatch()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isApplying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: isActive ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.title3)
                            }
                            Text(isApplying ? "ACTIVANDO..." : "ACTIVAR")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    isActive 
                                    ? AnyShapeStyle(Color.gray.opacity(0.2))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isActive ? Color.gray.opacity(0.3) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .disabled(isActive || isApplying || isRestoring)
                    .opacity(isActive ? 0.5 : 1)
                    
                    // DESACTIVAR button
                    Button {
                        if isActive && !isApplying && !isRestoring {
                            deactivatePatch()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isRestoring {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "xmark.circle")
                                    .font(.title3)
                            }
                            Text(isRestoring ? "DESACTIVANDO..." : "DESACTIVAR")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(isActive ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    !isActive 
                                    ? AnyShapeStyle(Color(.secondarySystemBackground))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    !isActive ? Color.clear : Color.red.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    }
                    .disabled(!isActive || isApplying || isRestoring)
                    .opacity(!isActive ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: isActive) { active in
            if !isApplying && !isRestoring {
                // Auto-dismiss after successful operation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    dismiss()
                }
            }
        }
    }
    
    private func activatePatch() {
        isApplying = true
        SoundPlayer.shared.playActivate()
        
        Task {
            do {
                guard let project = patchProject else {
                    throw NSError(domain: "PatchControl", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Patch project not found"
                    ])
                }
                
                _ = try DevicePatchService.apply(project: project)
                log("patchControl: apply done \(project.name)")
                
                await MainActor.run {
                    patchStore.reload()
                    isApplying = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isApplying = false
                }
            }
        }
    }
    
    private func deactivatePatch() {
        isRestoring = true
        SoundPlayer.shared.playDeactivate()
        
        Task {
            do {
                guard let receipt = receipt else {
                    throw NSError(domain: "PatchControl", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "No active receipt found"
                    ])
                }
                
                try DevicePatchService.restore(receipt: receipt, allowChangedTargets: true)
                log("patchControl: restore verified")
                
                await MainActor.run {
                    patchStore.reload()
                    isRestoring = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isRestoring = false
                }
            }
        }
    }
}
