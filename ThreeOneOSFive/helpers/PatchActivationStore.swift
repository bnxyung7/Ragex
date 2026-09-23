import Combine
import Foundation
import Security

struct PatchActivationEvent: Codable, Identifiable {
    let id: UUID
    let productId: String
    let displayName: String
    let activated: Bool
    let date: Date
}

struct AppliedPatchRef: Codable {
    let productId: String
    let projectID: UUID
    let transactionID: UUID
    let journalPath: String
}

@MainActor
final class PatchActivationStore: ObservableObject {
    static let shared = PatchActivationStore()

    @Published private(set) var activeIDs: Set<String> = []
    @Published private(set) var applied: [String: AppliedPatchRef] = [:]
    @Published private(set) var history: [PatchActivationEvent] = []
    @Published var historyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(historyEnabled, forKey: historyEnabledKey)
            if !historyEnabled {
                clearHistory()
            } else {
                persist()
            }
        }
    }

    private let defaultsKey = "x.patch.activation.v1"
    private let historyEnabledKey = "x.patch.activation.history.enabled"
    private let generationKey = "x.patch.activation.generation"
    private let currentGeneration = "3.1.1-17"
    private let historyLimit = 80
    private let keychainService = "x.patch.activation"
    private let keychainAccount = "snapshot.v1"

    private struct Snapshot: Codable {
        var activeIDs: [String]
        var history: [PatchActivationEvent]
        var applied: [AppliedPatchRef]?
    }

    private init() {
        historyEnabled = UserDefaults.standard.object(forKey: historyEnabledKey) as? Bool ?? false
        load()
        resetIfNewInstall()
        if !historyEnabled, !history.isEmpty {
            clearHistory()
        }
    }

    func isActive(_ patch: BundlePatch) -> Bool {
        activeIDs.contains(patch.productId)
    }

    func appliedRef(for productId: String) -> AppliedPatchRef? {
        applied[productId]
    }

    func record(
        patch: BundlePatch,
        activated: Bool,
        recordHistory: Bool = true,
        receipt: PatchTransactionReceipt? = nil
    ) {
        if activated {
            activeIDs.insert(patch.productId)
            if let receipt {
                applied[patch.productId] = AppliedPatchRef(
                    productId: patch.productId,
                    projectID: receipt.projectID,
                    transactionID: receipt.id,
                    journalPath: receipt.journalURL.path
                )
            }
        } else {
            activeIDs.remove(patch.productId)
            applied.removeValue(forKey: patch.productId)
        }
        if recordHistory, historyEnabled {
            history.insert(
                PatchActivationEvent(
                    id: UUID(),
                    productId: patch.productId,
                    displayName: patch.displayName,
                    activated: activated,
                    date: Date()
                ),
                at: 0
            )
            if history.count > historyLimit {
                history = Array(history.prefix(historyLimit))
            }
        }
        persist()
    }

    func clearHistory() {
        history = []
        persist()
    }

    func resetAllActivations() {
        activeIDs = []
        applied = [:]
        history = []
        persist()
        deleteKeychain()
    }

    private func resetIfNewInstall() {
        let stored = UserDefaults.standard.string(forKey: generationKey)
        if stored != currentGeneration {
            resetAllActivations()
            UserDefaults.standard.set(currentGeneration, forKey: generationKey)
        }
    }

    private func persist() {
        let snapshot = Snapshot(
            activeIDs: Array(activeIDs),
            history: history,
            applied: Array(applied.values)
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
        deleteKeychain()
        guard let url = fileURL else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private func load() {
        var data: Data?
        if let url = fileURL {
            data = try? Data(contentsOf: url)
        }
        if data == nil {
            data = UserDefaults.standard.data(forKey: defaultsKey)
        }
        guard let data,
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return
        }
        activeIDs = Set(snapshot.activeIDs)
        history = snapshot.history
        applied = Dictionary(
            uniqueKeysWithValues: (snapshot.applied ?? []).map { ($0.productId, $0) }
        )
    }

    private var fileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            .map { $0.appendingPathComponent("x.patch.activation.json") }
    }

    private func deleteKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
