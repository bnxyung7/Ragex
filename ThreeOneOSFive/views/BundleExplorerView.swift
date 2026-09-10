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
        
        Task.detached { @Sendable in
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
        var apps: [InstalledApp] = []
        let fileManager = FileManager.default
        
        // Scan Bundle containers first (FreeFire.app, etc.)
        let bundleRoot = "/var/containers/Bundle/Application"
        
        if let bundleContainers = try? fileManager.contentsOfDirectory(atPath: bundleRoot) {
            for containerUUID in bundleContainers {
                guard UUID(uuidString: containerUUID) != nil else { continue }
                
                let containerPath = "\(bundleRoot)/\(containerUUID)"
                let handle = grantContainerAccess(containerPath)
                defer {
                    if handle >= 0 { bad_query_release(handle) }
                }
                
                // Find the .app folder inside
                if let contents = try? fileManager.contentsOfDirectory(atPath: containerPath) {
                    for item in contents {
                        if item.hasSuffix(".app") {
                            let appPath = "\(containerPath)/\(item)"
                            
                            // Read Info.plist to get bundle ID and name
                            let infoPlistPath = "\(appPath)/Info.plist"
                            if let plistData = try? Data(contentsOf: URL(fileURLWithPath: infoPlistPath)),
                               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
                               let bundleID = plist["CFBundleIdentifier"] as? String {
                                
                                let displayName = plist["CFBundleDisplayName"] as? String 
                                    ?? plist["CFBundleName"] as? String 
                                    ?? item.replacingOccurrences(of: ".app", with: "")
                                
                                apps.append(InstalledApp(
                                    bundleID: bundleID,
                                    name: displayName,
                                    containerPath: appPath,  // Point to FreeFire.app
                                    version: plist["CFBundleShortVersionString"] as? String ?? "",
                                    icon: nil
                                ))
                                break
                            }
                        }
                    }
                }
            }
        }
        
        // Also scan Data containers for apps without bundles
        let dataRoot = "/var/mobile/Containers/Data/Application"
        if let dataContainers = try? fileManager.contentsOfDirectory(atPath: dataRoot) {
            for containerUUID in dataContainers {
                guard UUID(uuidString: containerUUID) != nil else { continue }
                
                let containerPath = "\(dataRoot)/\(containerUUID)"
                let handle = grantContainerAccess(containerPath)
                defer {
                    if handle >= 0 { bad_query_release(handle) }
                }
                
                let metadataPath = "\(containerPath)/.com.apple.mobile_container_manager.metadata.plist"
                if let metadataData = try? Data(contentsOf: URL(fileURLWithPath: metadataPath)),
                   let metadata = try? PropertyListSerialization.propertyList(from: metadataData, format: nil) as? [String: Any],
                   let bundleID = metadata["MCMMetadataIdentifier"] as? String {
                    
                    // Only add if not already in list
                    if !apps.contains(where: { $0.bundleID == bundleID }) {
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
            }
        }
        
        return apps.sorted { $0.displayName < $1.displayName }
    }
    
    private func grantContainerAccess(_ path: String) -> Int64 {
        // Use bad_query to grant temporary access to container
        let clean = path.hasSuffix("/") ? String(path.dropLast()) : path
        var pathC = clean.utf8CString.map { Int8($0) }
        return bad_query(&pathC, true, nil, false)
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
    
    // Replace system
    @State private var replacementRequest: FileReplacementRequest?
    @State private var replacementNotice: BundleOperationNotice?
    @State private var activityText: String?
    
    // Create Patch system (using PatchDraftCoordinator like Files tab)
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @Environment(\.appLanguage) private var language
    
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
                                .contextMenu {
                                    fileActions(for: item)
                                }
                            } else {
                                FileSystemRow(item: item)
                                    .contextMenu {
                                        fileActions(for: item)
                                    }
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
        .sheet(item: $replacementRequest) { (request: FileReplacementRequest) in
            BundleFileDocumentPicker(
                allowsMultipleSelection: false,
                onSelection: { result in
                    handleReplacementImport(result, request: request)
                    replacementRequest = nil
                },
                onCancel: {
                    replacementRequest = nil
                }
            )
        }
        .alert(item: $replacementNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if let text = activityText {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text(text)
                            .foregroundStyle(.white)
                            .font(.subheadline)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray))
                    )
                }
            }
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
    
    @ViewBuilder
    private func fileActions(for item: FileSystemItem) -> some View {
        // Replace (only for files)
        if !item.isDirectory {
            Button {
                requestReplacement(for: item)
            } label: {
                Label("Replace", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        
        // Create Patch (only for files)
        if !item.isDirectory {
            Button {
                requestCreatePatch(for: item)
            } label: {
                Label("Create Patch", systemImage: "shippingbox.fill")
            }
        }
        
        Divider()
        
        // Share
        ShareLink(item: item.url) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        // Copy path to clipboard
        Button {
            UIPasteboard.general.string = item.url.path
        } label: {
            Label("Copy Path", systemImage: "doc.on.doc")
        }
        
        Divider()
        
        // View Info
        Button {
            showFileInfo(for: item)
        } label: {
            Label("Info", systemImage: "info.circle")
        }
    }
    
    // MARK: - Replace System
    
    private func requestReplacement(for item: FileSystemItem) {
        replacementRequest = FileReplacementRequest(
            targetURL: item.url,
            targetName: item.name
        )
    }
    
    private func handleReplacementImport(_ result: Result<[URL], Error>, request: FileReplacementRequest) {
        guard case .success(let urls) = result, let sourceURL = urls.first else {
            return
        }
        
        activityText = "Replacing file..."
        
        Task.detached {
            do {
                let fileManager = FileManager.default
                
                // Start accessing security-scoped resource
                let canAccess = sourceURL.startAccessingSecurityScopedResource()
                defer {
                    if canAccess {
                        sourceURL.stopAccessingSecurityScopedResource()
                    }
                }
                
                // Copy to temp location first (iOS security requirement)
                let tempDir = fileManager.temporaryDirectory
                let tempFile = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(sourceURL.pathExtension)
                
                if fileManager.fileExists(atPath: tempFile.path) {
                    try? fileManager.removeItem(at: tempFile)
                }
                
                try fileManager.copyItem(at: sourceURL, to: tempFile)
                
                // Backup original file
                let backupURL = request.targetURL.appendingPathExtension("backup")
                if fileManager.fileExists(atPath: backupURL.path) {
                    try? fileManager.removeItem(at: backupURL)
                }
                try fileManager.copyItem(at: request.targetURL, to: backupURL)
                
                // Replace file with temp file
                try fileManager.removeItem(at: request.targetURL)
                try fileManager.copyItem(at: tempFile, to: request.targetURL)
                
                // Clean up temp file
                try? fileManager.removeItem(at: tempFile)
                
                await MainActor.run {
                    activityText = nil
                    replacementNotice = BundleOperationNotice(
                        title: "Success",
                        message: "File '\(request.targetName)' replaced successfully.\nBackup saved as '\(request.targetName).backup'"
                    )
                    loadContents()
                }
            } catch {
                await MainActor.run {
                    activityText = nil
                    replacementNotice = BundleOperationNotice(
                        title: "Error",
                        message: "Failed to replace file: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    // MARK: - Create Patch System (same as Files tab)
    
    private func requestCreatePatch(for item: FileSystemItem) {
        let itemURL = item.url
        let containerURL = URL(fileURLWithPath: app.containerPath, isDirectory: true)
        let suggestedName = item.isDirectory
            ? item.name
            : itemURL.deletingPathExtension().lastPathComponent
        
        activityText = language.text("patch.preparing_from_browser")
        
        Task.detached {
            do {
                let draft = try PatchDraftService.makeDraft(
                    bundleID: app.bundleID,
                    containerRoot: containerURL,
                    itemURL: itemURL,
                    suggestedName: suggestedName
                )
                
                await MainActor.run {
                    activityText = nil
                    patchDraftCoordinator.present(draft)
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    activityText = nil
                    showPatchCreationError(error)
                }
            } catch {
                await MainActor.run {
                    activityText = nil
                    showPatchCreationError(.invalidProject)
                }
            }
        }
    }
    
    private func showPatchCreationError(_ error: PatchPackageError) {
        let message: String
        switch error {
        case .invalidProject:
            message = "Invalid patch project structure"
        case .archiveFailure:
            message = "Failed to create patch archive"
        case .compressionFailure:
            message = "Failed to compress patch"
        case .encryptionFailure:
            message = "Failed to encrypt patch"
        case .missingBundleIdentifier:
            message = "Missing bundle identifier"
        case .unsupportedFormat:
            message = "Unsupported file format"
        }
        
        replacementNotice = BundleOperationNotice(
            title: "Patch Creation Failed",
            message: message
        )
    }
    
    private func showFileInfo(for item: FileSystemItem) {
        let sizeText = formatFileSize(item.size)
        let dateText = item.modificationDate.map { formatDate($0) } ?? "Unknown"
        let pathText = item.url.path
        
        replacementNotice = BundleOperationNotice(
            title: item.name,
            message: "Size: \(sizeText)\nModified: \(dateText)\nPath: \(pathText)"
        )
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

// MARK: - Supporting Types

struct BundleOperationNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct BundleFileDocumentPicker: UIViewControllerRepresentable {
    let allowsMultipleSelection: Bool
    let onSelection: (Result<[URL], Error>) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item, .data, .content])
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: BundleFileDocumentPicker
        
        init(_ parent: BundleFileDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onSelection(.success(urls))
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel()
        }
    }
}
