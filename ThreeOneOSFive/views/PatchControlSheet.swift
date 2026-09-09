import SwiftUI

struct PatchControlSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var devicePatchService: DevicePatchService
    
    let patch: BundlePatch
    
    @State private var isApplying = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    private var isActive: Bool {
        devicePatchService.activePatchKeys.contains(patch.id)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with patch info
                VStack(spacing: 12) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 60))
                        .foregroundStyle(isActive ? .green : .gray)
                    
                    Text(patch.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    if isActive {
                        Text("ACTIVE")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(8)
                    } else {
                        Text("INACTIVE")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                Spacer()
                
                // Control buttons
                VStack(spacing: 16) {
                    // ACTIVAR button
                    Button {
                        activatePatch()
                    } label: {
                        HStack(spacing: 12) {
                            if isApplying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                            }
                            Text(isApplying ? "ACTIVANDO..." : "ACTIVAR")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(
                            LinearGradient(
                                colors: isActive ? [.gray, .gray.opacity(0.8)] : [.green, .green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(isActive || isApplying || isRestoring)
                    .opacity(isActive ? 0.5 : 1)
                    
                    // DESACTIVAR button
                    Button {
                        deactivatePatch()
                    } label: {
                        HStack(spacing: 12) {
                            if isRestoring {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                            }
                            Text(isRestoring ? "DESACTIVANDO..." : "DESACTIVAR")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(
                            LinearGradient(
                                colors: !isActive ? [.gray, .gray.opacity(0.8)] : [.red, .red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(!isActive || isApplying || isRestoring)
                    .opacity(!isActive ? 0.5 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("Patch Control")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
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
        
        Task {
            do {
                // Check for conflicts
                let conflicts = await devicePatchService.detectConflicts(for: patch.id, in: patchStore)
                
                if !conflicts.isEmpty {
                    await MainActor.run {
                        errorMessage = "Conflict detected with: \(conflicts.map { $0.displayName }.joined(separator: ", ")). Please deactivate conflicting patches first."
                        showError = true
                        isApplying = false
                    }
                    return
                }
                
                // Apply patch
                try await devicePatchService.apply(patchKey: patch.id, in: patchStore)
                
                await MainActor.run {
                    // Play activation sound
                    SoundPlayer.shared.playActivate()
                    
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
        
        Task {
            do {
                try await devicePatchService.restore(patchKey: patch.id, in: patchStore)
                
                await MainActor.run {
                    // Play deactivation sound
                    SoundPlayer.shared.playDeactivate()
                    
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
