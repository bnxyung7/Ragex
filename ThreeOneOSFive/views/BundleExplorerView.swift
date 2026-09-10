import SwiftUI

/// Bundle Explorer - Browse all installed apps like File App Data
struct BundleExplorerView: View {
    @State private var apps: [InstalledApp] = []
    @State private var searchText = ""
    @State private var isLoading = false
    
    private var filteredApps: [InstalledApp] {
        if searchText.isEmpty {
            return apps
        } else {
            return apps.filter { app in
                app.displayName.localizedCaseInsensitiveContains(searchText) ||
                app.bundleID.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading apps...")
                } else if apps.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "app.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("No apps found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            loadApps()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    List {
                        if !searchText.isEmpty {
                            Section {
                                Text("Found \(filteredApps.count) apps")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Section {
                            ForEach(filteredApps) { app in
                                NavigationLink {
                                    AppBundleBrowserView(app: app)
                                } label: {
                                    AppBundleRow(app: app)
                                }
                            }
                        } header: {
                            Text("Installed Apps (\(apps.count))")
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search apps...")
                }
            }
            .navigationTitle("File App Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        loadApps()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            if apps.isEmpty {
                loadApps()
            }
        }
    }
    
    private func loadApps() {
        isLoading = true
        
        Task.detached {
            // Try API first (works with exploit/jailbreak)
            var loadedApps = ContainerStore.installedAppsFromAPI()
            
            // If API returns empty, use filesystem scan (works without jailbreak)
            if loadedApps.isEmpty {
                loadedApps = await scanAppsFromFilesystem()
            }
            
            // Final fallback: at least show current app
            if loadedApps.isEmpty {
                let homeDir = NSHomeDirectory()
                loadedApps = [
                    InstalledApp(
                        bundleID: Bundle.main.bundleIdentifier ?? "com.x.app",
                        name: "X (This App)",
                        containerPath: homeDir,
                        version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                        icon: nil
                    )
                ]
            }
            
            await MainActor.run {
                apps = loadedApps
                isLoading = false
            }
        }
    }
    
    private func scanAppsFromFilesystem() async -> [InstalledApp] {
        let appDataRoot = "/var/mobile/Containers/Data/Application"
        let fileManager = FileManager.default
        var apps: [InstalledApp] = []
        
        // Get all container directories
        guard let containers = try? fileManager.contentsOfDirectory(atPath: appDataRoot) else {
            return []
        }
        
        for containerUUID in containers {
            // Verify it's a valid UUID
            guard UUID(uuidString: containerUUID) != nil else { continue }
            
            let containerPath = "\(appDataRoot)/\(containerUUID)"
            
            // Grant access to this container using bad_query
            let handle = grantContainerAccess(containerPath)
            defer {
                if handle >= 0 { bad_query_release(handle) }
            }
            
            // Try to read metadata plist
            let metadataPath = "\(containerPath)/.com.apple.mobile_container_manager.metadata.plist"
            
            if let metadataData = try? Data(contentsOf: URL(fileURLWithPath: metadataPath)),
               let metadata = try? PropertyListSerialization.propertyList(from: metadataData, format: nil) as? [String: Any],
               let bundleID = metadata["MCMMetadataIdentifier"] as? String {
                
                // Get display name from metadata or use bundle ID
                var displayName = bundleID
                if let metadataInfo = metadata["MCMMetadataInfo"] as? [String: Any],
                   let name = metadataInfo["DisplayName"] as? String, !name.isEmpty {
                    displayName = name
                }
                
                apps.append(InstalledApp(
                    bundleID: bundleID,
                    name: displayName,
                    containerPath: containerPath,
                    version: "",
                    icon: nil
                ))
            }
        }
        
        return apps.sorted { $0.displayName < $1.displayName }
    }
    
    private func grantContainerAccess(_ path: String) -> Int32 {
        // Use bad_query to grant temporary access to container
        return bad_query(path, 0)
    }
}

struct AppBundleRow: View {
    let app: InstalledApp
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon
            if let iconImage = app.icon {
                Image(uiImage: iconImage)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "app.fill")
                            .foregroundStyle(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(app.bundleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct AppBundleBrowserView: View {
    let app: InstalledApp
    @State private var currentPath: URL
    @State private var items: [FileSystemItem] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    init(app: InstalledApp) {
        self.app = app
        self._currentPath = State(initialValue: URL(fileURLWithPath: app.containerPath))
    }
    
    private var filteredItems: [FileSystemItem] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading...")
            } else if items.isEmpty {
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
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Path")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(currentPath.lastPathComponent)
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                    .lineLimit(1)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                                .foregroundStyle(.green)
                            Text("\(items.filter { !$0.isDirectory }.count) files, \(items.filter { $0.isDirectory }.count) folders")
                                .font(.caption)
                        }
                    }
                    
                    Section {
                        ForEach(filteredItems, id: \.id) { item in
                            if item.isDirectory {
                                NavigationLink {
                                    AppBundleBrowserView(app: app, currentPath: item.url)
                                } label: {
                                    FileSystemRow(item: item)
                                }
                            } else {
                                FileSystemRow(item: item)
                            }
                        }
                    } header: {
                        Text(searchText.isEmpty ? "Contents" : "Search Results")
                    }
                }
                .searchable(text: $searchText, prompt: "Search files...")
            }
        }
        .navigationTitle(currentPath.path == app.containerPath ? app.displayName : currentPath.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    loadContents()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            loadContents()
        }
    }
    
    init(app: InstalledApp, currentPath: URL) {
        self.app = app
        self._currentPath = State(initialValue: currentPath)
    }
    
    private func loadContents() {
        isLoading = true
        
        Task {
            let contents = scanDirectory(at: currentPath)
            
            await MainActor.run {
                items = contents
                isLoading = false
            }
        }
    }
    
    private func scanDirectory(at url: URL) -> [FileSystemItem] {
        let fileManager = FileManager.default
        var items: [FileSystemItem] = []
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        for fileURL in contents {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
                continue
            }
            
            if isDirectory.boolValue {
                items.append(FileSystemItem(
                    name: fileURL.lastPathComponent,
                    url: fileURL,
                    size: 0,
                    isDirectory: true,
                    modificationDate: (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                ))
            } else {
                let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                items.append(FileSystemItem(
                    name: fileURL.lastPathComponent,
                    url: fileURL,
                    size: Int64(fileSize),
                    isDirectory: false,
                    modificationDate: (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                ))
            }
        }
        
        return items.sorted { item1, item2 in
            if item1.isDirectory && !item2.isDirectory {
                return true
            } else if !item1.isDirectory && item2.isDirectory {
                return false
            } else {
                return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            }
        }
    }
}

struct FileSystemRow: View {
    let item: FileSystemItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isDirectory ? "folder.fill" : iconForFile(item))
                .foregroundStyle(item.isDirectory ? .blue : colorForFile(item))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let date = item.modificationDate {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if !item.isDirectory {
                Text(formatFileSize(item.size))
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
    
    private func iconForFile(_ item: FileSystemItem) -> String {
        let ext = item.url.pathExtension.lowercased()
        switch ext {
        case "3105":
            return "shippingbox.fill"
        case "png", "jpg", "jpeg", "gif", "heic":
            return "photo.fill"
        case "plist":
            return "doc.text.fill"
        case "wav", "mp3", "m4a":
            return "music.note"
        case "db", "sqlite", "sqlite3":
            return "cylinder.fill"
        case "json":
            return "curlybraces"
        case "txt", "log":
            return "doc.plaintext.fill"
        case "zip", "ipa":
            return "doc.zipper"
        default:
            return "doc.fill"
        }
    }
    
    private func colorForFile(_ item: FileSystemItem) -> Color {
        let ext = item.url.pathExtension.lowercased()
        switch ext {
        case "3105":
            return .orange
        case "png", "jpg", "jpeg", "gif", "heic":
            return .purple
        case "plist":
            return .green
        case "wav", "mp3", "m4a":
            return .pink
        case "db", "sqlite", "sqlite3":
            return .cyan
        case "json":
            return .blue
        case "txt", "log":
            return .gray
        case "zip", "ipa":
            return .yellow
        default:
            return .secondary
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FileSystemItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let size: Int64
    let isDirectory: Bool
    let modificationDate: Date?
}
