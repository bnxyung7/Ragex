import Foundation

enum DevicePatchService {
    static func apply(project: PatchProject) throws -> PatchTransactionReceipt {
        let bundleIDs = orderedBundleIdentifiers(in: project)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.apply(
                project: project,
                backupRoot: try PatchProjectLibrary.backupRootURL(),
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
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
        allowChangedTargets: Bool = false
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.restore(
                receipt: receipt,
                allowChangedTargets: allowChangedTargets,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
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

    private static func orderedBundleIdentifiers(in project: PatchProject) -> [String] {
        project.allBundleIdentifiers
    }

    private static func withResolvedContainers<T>(
        bundleIDs: [String],
        operation: ([String: URL]) throws -> T
    ) throws -> T {
        var roots: [String: URL] = [:]

        for bundleID in bundleIDs {
            guard let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID),
                  ContainerStore.isApplicationContainerPath(path) else {
                throw PatchPackageError.targetAppUnavailable(bundleID)
            }
            roots[bundleID] = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
        }
        return try operation(roots)
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