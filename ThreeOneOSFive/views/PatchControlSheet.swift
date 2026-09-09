import SwiftUI

struct PatchControlSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var patchStore: PatchProjectStore
    
    let patch: BundlePatch
    
    @State private var isApplying = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    
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
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Status banner
                if isActive {
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 4)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OPCIÓN ACTIVADA")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Text(patch.displayName.uppercased())
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                // Patch info
                VStack(spacing: 16) {
                    Text(patch.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(isActive ? "Parche actualmente activado" : "Listo para activar")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // ACTIVADO button (when active, shows as disabled state)
                    Button {
                        if !isActive {
                            activatePatch()
                        }
                    } label: {
                        HStack {
                            if isApplying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isApplying ? "ACTIVANDO..." : "ACTIVADO")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isActive ? Color.red.opacity(0.3) : Color.red.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isActive ? Color.red : Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .disabled(isActive || isApplying || isRestoring)
                    
                    // DESACTIVAR button (when inactive, shows as disabled state)
                    Button {
                        if isActive {
                            deactivatePatch()
                        }
                    } label: {
                        HStack {
                            if isRestoring {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isRestoring ? "DESACTIVANDO..." : "DESACTIVAR")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(isActive ? .red : .gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isActive ? Color.red.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .disabled(!isActive || isApplying || isRestoring)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func activatePatch() {
        isApplying = true
        
        // Play sound immediately for better feedback
        SoundPlayer.shared.playActivate()
        
        Task {
            do {
                guard let project = patchProject else {
                    throw NSError(domain: "PatchControl", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Patch project not found"
                    ])
                }
                
                // Apply patch using static method
                _ = try DevicePatchService.apply(project: project)
                
                await MainActor.run {
                    patchStore.reload()
                    successMessage = "Patch activated successfully!"
                    showSuccess = true
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
        
        // Play sound immediately for better feedback
        SoundPlayer.shared.playDeactivate()
        
        Task {
            do {
                guard let receipt = receipt else {
                    throw NSError(domain: "PatchControl", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "No active receipt found for this patch"
                    ])
                }
                
                // Restore using static method
                try DevicePatchService.restore(receipt: receipt)
                
                await MainActor.run {
                    patchStore.reload()
                    successMessage = "Patch deactivated. Original files restored."
                    showSuccess = true
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
