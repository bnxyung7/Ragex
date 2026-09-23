import Foundation

enum DevicePatchService {
    static func apply(project: PatchProject) throws -> PatchTransactionReceipt {
        let bundleIDs = orderedBundleIdentifiers(in: project)
        log("patch: apply begin name=\(project.name) rules=\(project.rules.count) bundles=\(bundleIDs.joined(separator: ","))")
        let backupRoot = try PatchProjectLibrary.backupRootURL()
        let receipt = try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            log("patch: containers resolved \(roots.map { "\($0.key)=\($0.value.path)" }.joined(separator: " | "))")
            return try PatchTransaction.apply(
                project: project,
                backupRoot: backupRoot,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
        log("patch: apply verified name=\(project.name) receipt=\(receipt.id.uuidString)")
        return receipt
    }

    static func inspectRestore(receipt: PatchTransactionReceipt) throws -> PatchRestoreInspection {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.inspectRestore(
                receipt: receipt,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func restore(
        receipt: PatchTransactionReceipt,
        allowChangedTargets: Bool = true
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        log("patch: restore begin receipt=\(receipt.id.uuidString) bundles=\(bundleIDs.joined(separator: ","))")
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.restore(
                receipt: receipt,
                allowChangedTargets: allowChangedTargets,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                },
                strictContainerIdentity: false,
                snapshotCurrentFiles: false
            )
        }
        log("patch: restore verified receipt=\(receipt.id.uuidString)")
    }

    static func resetToAppliedState(
        receipt: PatchTransactionReceipt,
        project: PatchProject
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.resetToAppliedState(
                receipt: receipt,
                fallbackProject: project,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func latestReceipt(projectID: UUID) -> PatchTransactionReceipt? {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return nil }
        return PatchTransaction.latestReceipt(projectID: projectID, backupRoot: backupRoot)
    }

    static func receipt(for project: PatchProject) -> PatchTransactionReceipt? {
        if let receipt = latestReceipt(projectID: project.id) {
            return receipt
        }
        log("patch: no receipt for project \(project.id.uuidString), scanning overlapping applies")
        return appliedReceipts().first { PatchTransaction.overlaps(receipt: $0, project: project) }
    }

    static func verifyRestored(receipt: PatchTransactionReceipt) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.verifyRestored(
                receipt: receipt,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func appliedReceipts() -> [PatchTransactionReceipt] {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL(),
              let directories = try? FileManager.default.contentsOfDirectory(
                at: backupRoot,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
              ) else { return [] }
        return directories.compactMap { directory in
            guard let projectID = UUID(uuidString: directory.lastPathComponent) else { return nil }
            return latestReceipt(projectID: projectID)
        }
    }

    /// Puts original game files back without clearing saved toggle history.
    static func restoreAllOriginals() {
        for receipt in appliedReceipts() {
            try? restore(receipt: receipt, allowChangedTargets: true)
        }
    }

    static func isCurrentlyApplied(receipt: PatchTransactionReceipt) -> Bool {
        do {
            let inspection = try inspectRestore(receipt: receipt)
            if !inspection.changedTargets.isEmpty {
                log("patch: files drifted \(inspection.changedTargets.map(\.displayPath).joined(separator: ","))")
                return false
            }
            return true
        } catch {
            log("patch: verify failed \(error.localizedDescription)")
            return false
        }
    }

    static func verifyApplied(receipt: PatchTransactionReceipt) throws {
        guard isCurrentlyApplied(receipt: receipt) else {
            log("patch: post-write verification rejected receipt=\(receipt.id.uuidString)")
            throw PatchPackageError.applyFailed
        }
    }

    static func clearApplyReceipts() {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return }
        try? FileManager.default.removeItem(at: backupRoot)
        try? FileManager.default.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        log("patch: apply receipts cleared")
    }

    static func ensureContainerWriteAccess() {
        if KernelExploit.hasReadySession {
            return
        }
        log("patch: writing without a second kernel run")
    }

    private static func orderedBundleIdentifiers(in project: PatchProject) -> [String] {
        project.allBundleIdentifiers
    }

    private static func withResolvedContainers<T>(
        bundleIDs: [String],
        operation: ([String: URL]) throws -> T
    ) throws -> T {
        var roots: [String: URL] = [:]

        for bundleID in bundleIDs {
            guard let resolvedPath = resolveContainerPath(for: bundleID),
                  ContainerStore.isApplicationContainerPath(resolvedPath) else {
                throw PatchPackageError.targetAppUnavailable(bundleID)
            }
            roots[bundleID] = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: resolvedPath, isDirectory: true))
        }
        return try operation(roots)
    }

    private static func resolveContainerPath(for bundleID: String) -> String? {
        if let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID) {
            return path
        }

        if ContainerStore.isFreeFireBundle(bundleID) {
            var seen = Set<String>()
            seen.insert(bundleID.lowercased())
            for alias in ContainerStore.freeFireBundleIDs where seen.insert(alias.lowercased()).inserted {
                if let path = ContainerStore.resolveAppContainerPath(bundleID: alias) {
                    log("patch: Free Fire alias \(alias) resolved for \(bundleID)")
                    return path
                }
            }
            if let path = ContainerStore.resolveAppContainerPathMatching(ContainerStore.isFreeFireBundle) {
                log("patch: Free Fire container found by metadata for \(bundleID)")
                return path
            }
        }

        return nil
    }
    
    /// Detect if applying this project would conflict with already applied patches
    static func detectConflicts(
        project: PatchProject,
        allItems: [PatchLibraryItem]
    ) -> [ConflictingPatch] {
        // Get all paths this patch will modify
        let targetPaths = Set(project.rules.map { PatchPath(bundleID: $0.bundleID, relativePath: $0.relativePath) })
        
        var conflicts: [ConflictingPatch] = []
        
        // Check each other patch
        for item in allItems {
            guard item.id != project.id,
                  let otherProject = item.project,
                  let receipt = latestReceipt(projectID: otherProject.id) else {
                continue
            }
            
            // Check if this patch has any overlapping paths
            for rule in otherProject.rules {
                let path = PatchPath(bundleID: rule.bundleID, relativePath: rule.relativePath)
                if targetPaths.contains(path) {
                    conflicts.append(ConflictingPatch(
                        projectID: otherProject.id,
                        projectName: otherProject.name,
                        conflictingPath: "\(rule.bundleID)/\(rule.relativePath)",
                        receipt: receipt
                    ))
                    break // Only report each project once
                }
            }
        }
        
        return conflicts
    }
}

struct PatchPath: Hashable {
    let bundleID: String
    let relativePath: String
}

struct ConflictingPatch: Identifiable {
    let projectID: UUID
    let projectName: String
    let conflictingPath: String
    let receipt: PatchTransactionReceipt
    
    var id: UUID { projectID }
}