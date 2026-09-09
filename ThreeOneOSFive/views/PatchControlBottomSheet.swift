import SwiftUI

struct PatchControlBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var patchStore: PatchProjectStore
    
    let patch: BundlePatch
    
    @State private var isApplying = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                // Drag indicator is automatic with .presentationDragIndicator
                
                Text(patch.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if isActive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Activo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Inactivo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
            
            // Action buttons
            VStack(spacing: 12) {
                // ACTIVAR button
                Button {
                    if !isActive && !isApplying && !isRestoring {
                        activatePatch()
                    }
                } label: {
                    HStack {
                        if isApplying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isApplying ? "ACTIVANDO..." : "ACTIVAR")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isActive ? Color.gray.opacity(0.3) : Color.green)
                    )
                }
                .disabled(isActive || isApplying || isRestoring)
                
                // DESACTIVAR button
                Button {
                    if isActive && !isApplying && !isRestoring {
                        deactivatePatch()
                    }
                } label: {
                    HStack {
                        if isRestoring {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isRestoring ? "DESACTIVANDO..." : "DESACTIVAR")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(!isActive ? Color.gray.opacity(0.3) : Color.red)
                    )
                }
                .disabled(!isActive || isApplying || isRestoring)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: isActive) { active in
            if !isApplying && !isRestoring {
                // Auto-dismiss after successful operation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                
                try DevicePatchService.restore(receipt: receipt)
                
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
