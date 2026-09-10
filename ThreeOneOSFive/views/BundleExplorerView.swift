import SwiftUI

/// Bundle Explorer - View all files in the app bundle
struct BundleExplorerView: View {
    @State private var bundleFiles: [BundleFileItem] = []
    @State private var currentPath: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Scanning bundle...")
                } else if bundleFiles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("No files found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        Section {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Bundle Path")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(currentPath)
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundStyle(.green)
                                Text("Total Files: \(bundleFiles.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        } header: {
                            Text("Bundle Info")
                        }
                        
                        Section {
                            ForEach(bundleFiles) { file in
                                BundleFileRow(file: file)
                            }
                        } header: {
                            Text("Files")
                        }
                    }
                }
            }
            .navigationTitle("Bundle Explorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        loadBundleFiles()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            if bundleFiles.isEmpty {
                loadBundleFiles()
            }
        }
    }
    
    private func loadBundleFiles() {
        isLoading = true
        
        Task.detached {
            let files = scanBundleFiles()
            
            await MainActor.run {
                bundleFiles = files
                if let bundleURL = Bundle.main.resourceURL {
                    currentPath = bundleURL.path
                }
                isLoading = false
            }
        }
    }
    
    private func scanBundleFiles() -> [BundleFileItem] {
        guard let bundleURL = Bundle.main.resourceURL else {
            return []
        }
        
        let fileManager = FileManager.default
        var files: [BundleFileItem] = []
        
        // Scan recursively
        if let enumerator = fileManager.enumerator(
            at: bundleURL,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
                    continue
                }
                
                let relativePath = fileURL.path.replacingOccurrences(of: bundleURL.path + "/", with: "")
                
                if isDirectory.boolValue {
                    files.append(BundleFileItem(
                        name: fileURL.lastPathComponent,
                        path: relativePath,
                        size: 0,
                        isDirectory: true,
                        extension: ""
                    ))
                } else {
                    let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                    files.append(BundleFileItem(
                        name: fileURL.lastPathComponent,
                        path: relativePath,
                        size: Int64(fileSize),
                        isDirectory: false,
                        extension: fileURL.pathExtension
                    ))
                }
            }
        }
        
        return files.sorted { $0.path < $1.path }
    }
}

struct BundleFileRow: View {
    let file: BundleFileItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: file.isDirectory ? "folder.fill" : iconForFile(file))
                .foregroundStyle(file.isDirectory ? .blue : colorForFile(file))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(file.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if !file.isDirectory {
                Text(formatFileSize(file.size))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForFile(_ file: BundleFileItem) -> String {
        switch file.extension.lowercased() {
        case "3105":
            return "shippingbox.fill"
        case "png", "jpg", "jpeg", "gif":
            return "photo.fill"
        case "plist":
            return "doc.text.fill"
        case "wav", "mp3":
            return "music.note"
        case "swift":
            return "swift"
        default:
            return "doc.fill"
        }
    }
    
    private func colorForFile(_ file: BundleFileItem) -> Color {
        switch file.extension.lowercased() {
        case "3105":
            return .orange
        case "png", "jpg", "jpeg", "gif":
            return .purple
        case "plist":
            return .green
        case "wav", "mp3":
            return .pink
        case "swift":
            return .red
        default:
            return .secondary
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct BundleFileItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let isDirectory: Bool
    let `extension`: String
}
