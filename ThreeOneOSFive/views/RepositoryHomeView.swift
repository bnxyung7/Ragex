import SwiftUI

struct RepositoryHomeView: View {
    @Environment(\.appLanguage) private var language

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                    
                    // App Icon
                    Image(systemName: "folder.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(AppTheme.accent)
                    
                    // App Name
                    Text("X")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    // Simple description
                    Text("File Manager")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                        .frame(height: 60)
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        NavigationButton(
                            title: language.text("home.settings"),
                            icon: "gearshape.fill",
                            action: onOpenSettings
                        )
                        
                        NavigationButton(
                            title: language.text("home.logs"),
                            icon: "list.bullet.rectangle.fill",
                            action: onOpenLogs
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("X")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct NavigationButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 32)
                
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color(uiColor: .systemBackground),
                in: RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        Color(uiColor: .separator).opacity(0.24),
                        lineWidth: 0.5
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// Empty placeholder views for removed functionality
struct RepositoryNewView: View {
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    
    var body: some View {
        Text("Removed")
    }
}

struct RepositorySearchView: View {
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    
    var body: some View {
        Text("Removed")
    }
}
