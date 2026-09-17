import SwiftUI

/// Force Update Screen - Blocks app when version is disabled
struct ForceUpdateView: View {
    let versionStatus: KeyAPIService.VersionStatusResponse
    
    var body: some View {
        ZStack {
            Color(hex: "06060E")
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Warning Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "EF4444").opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .stroke(Color(hex: "EF4444").opacity(0.4), lineWidth: 2)
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(Color(hex: "EF4444"))
                }
                
                VStack(spacing: 16) {
                    Text("Actualización Requerida")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    if let message = versionStatus.message {
                        Text(message)
                            .font(.body)
                            .foregroundStyle(Color(hex: "94A3B8"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else {
                        Text("Esta versión de la aplicación ya no está disponible. Por favor, actualiza a la última versión para continuar.")
                            .font(.body)
                            .foregroundStyle(Color(hex: "94A3B8"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                
                VStack(spacing: 12) {
                    versionInfoRow(
                        label: "Versión actual",
                        value: versionStatus.currentVersion,
                        color: "EF4444"
                    )
                    
                    if let minimumVersion = versionStatus.minimumVersion {
                        versionInfoRow(
                            label: "Versión mínima",
                            value: minimumVersion,
                            color: "F59E0B"
                        )
                    }
                    
                    if let latestVersion = versionStatus.latestVersion {
                        versionInfoRow(
                            label: "Última versión",
                            value: latestVersion,
                            color: "10B981"
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Download Button
                if let downloadURL = versionStatus.downloadURL, let url = URL(string: downloadURL) {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Descargar Actualización")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "10B981"),
                                            Color(hex: "059669")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color(hex: "10B981").opacity(0.5), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
        }
    }
    
    private func versionInfoRow(label: String, value: String, color: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "94A3B8"))
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
    }
}
