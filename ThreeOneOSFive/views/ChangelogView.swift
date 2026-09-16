import SwiftUI

struct ChangelogVersion: Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let isLatest: Bool
    let added: [String]
    let changed: [String]
    let fixed: [String]
    let compatibility: [String]
}

struct ChangelogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    
    private let versions: [ChangelogVersion] = [
        ChangelogVersion(
            version: "1.0.1",
            date: "2026-08-15",
            isLatest: true,
            added: [
                "Bundle-tree Patch workspace v2 under `On My iPhone/X/Patches`, synchronized automatically when applying or exporting.",
                "Multiple independent Files tabs with preserved navigation state.",
                "ZIP extraction with path, symbolic-link, CRC, and available-space validation.",
                "Responsive iPad split-view and landscape navigation.",
                "Home toggles for showing or hiding Cleaner and Wallpaper features."
            ],
            changed: [
                "Patch creation from an app-container file or folder now captures the stable bundle identifier and editable destination tree automatically.",
                "Patch package imports no longer use the previous fixed payload-size or file-count ceiling; practical device storage and memory still apply.",
                "Files and Patch screens now use consistent grouped cards, compact icons, balanced nested rows, and stable search presentation.",
                "Legacy v1 `.3105` packages remain importable and usable."
            ],
            fixed: [
                "Patch Restore now restores files that existed before Apply, removes files introduced by the patch, and removes patch-created folders after they become empty.",
                "File navigation remains at the current folder when switching app sections and restores the correct folder independently for each Files tab.",
                "Empty Patch and Cleaner actions now share the same visual treatment.",
                "Corrected PosterBoard wallpaper activation guidance and the iOS 27 Collections prerequisite.",
                "Refined navigation icon rendering and nested file-row spacing."
            ],
            compatibility: [
                "Verified iOS 26.0–26.6.1.",
                "Verified iOS 27 Developer Beta 1–4, including Public Beta 1–2 mappings listed in the app.",
                "Added iPhone and iPad interface support; device-level features still require enterprise signing."
            ]
        ),
        ChangelogVersion(
            version: "1.0 beta 3",
            date: "2026-08-14",
            isLatest: false,
            added: [
                "Bundle-based App Data Browser with MHA-C2 container discovery.",
                "Native file operations: search, multi-file import, rename, delete, create file/folder, and conflict handling.",
                "Portable `.3105` patch projects with optional password protection and file/folder rules.",
                "Limited per-app cleaner for `Library/Caches` and `tmp`.",
                "Wallpaper Lab for validated `.tendies` packages with installation receipts and targeted reset.",
                "English, Vietnamese, and Simplified Chinese localization."
            ],
            changed: [
                "Simplified the app into a five-tab, native SwiftUI layout inspired by focused iOS container tools.",
                "Moved the enterprise-signing notice below device information on Home.",
                "Refined the orange accent, empty states, actions, and navigation presentation."
            ],
            fixed: [
                "Stabilized persistent search presentation in app and file browsers.",
                "Fixed native document selection for replacement files and `.3105` package imports.",
                "Resolved bundle-name mapping for enumerated app containers where metadata is available.",
                "Limited wallpaper reset to active content installed by X.",
                "Corrected Cleaner layout when no removable app data is found."
            ],
            compatibility: [
                "Verified iOS 26.0–26.6.1.",
                "Verified iOS 27 beta 1–4 builds listed in the app.",
                "Unlisted iOS 27 builds remain disabled until explicitly verified."
            ]
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(versions) { version in
                    VersionCard(version: version)
                        .padding(.horizontal, 16)
                        .padding(.top, versions.first?.id == version.id ? 16 : 8)
                        .padding(.bottom, versions.last?.id == version.id ? 16 : 8)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Updates")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .fontWeight(.semibold)
            }
        }
    }
}

struct VersionCard: View {
    let version: ChangelogVersion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Version \(version.version)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if version.isLatest {
                            Text("Latest Update")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    
                    Spacer()
                    
                    Text(version.date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .background(Color(.systemBackground))
            
            Divider()
                .padding(.horizontal, 16)
            
            // Content
            VStack(alignment: .leading, spacing: 20) {
                if !version.added.isEmpty {
                    ChangeSection(
                        title: "New Features",
                        icon: "sparkles",
                        iconColor: .blue,
                        items: version.added
                    )
                }
                
                if !version.changed.isEmpty {
                    ChangeSection(
                        title: "Improvements",
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: .orange,
                        items: version.changed
                    )
                }
                
                if !version.fixed.isEmpty {
                    ChangeSection(
                        title: "Bug Fixes",
                        icon: "wrench.and.screwdriver.fill",
                        iconColor: .green,
                        items: version.fixed
                    )
                }
                
                if !version.compatibility.isEmpty {
                    ChangeSection(
                        title: "Compatibility",
                        icon: "checkmark.seal.fill",
                        iconColor: .purple,
                        items: version.compatibility
                    )
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ChangeSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.secondary)
                            .font(.body)
                        
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 4)
        }
    }
}

#Preview {
    NavigationStack {
        ChangelogView()
    }
}
