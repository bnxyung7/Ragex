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

@MainActor
final class PatchActivationStore: ObservableObject {
    static let shared = PatchActivationStore()

    @Published private(set) var activeIDs: Set<String> = []
    @Published private(set) var history: [PatchActivationEvent] = []
    @Published var historyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(historyEnabled, forKey: historyEnabledKey)
            if !historyEnabled {
                history = []
                persist()
            } else {
                persist()
            }
        }
    }

    private let defaultsKey = "x.patch.activation.v1"
    private let historyEnabledKey = "x.patch.activation.history.enabled"
    private let resetTokenKey = "x.patch.activation.resetToken"
    private let resetToken = "clean-on-launch-v1"
    private let historyLimit = 80
    private let keychainService = "x.patch.activation"
    private let keychainAccount = "snapshot.v1"

    private struct Snapshot: Codable {
        var activeIDs: [String]
        var history: [PatchActivationEvent]
    }

    private init() {
        historyEnabled = UserDefaults.standard.object(forKey: historyEnabledKey) as? Bool ?? false
        if UserDefaults.standard.string(forKey: resetTokenKey) != resetToken {
            wipePersistedState()
            UserDefaults.standard.set(resetToken, forKey: resetTokenKey)
            DevicePatchService.clearApplyReceipts()
            activeIDs = []
            history = []
            persist()
            return
        }
        load()
        if !historyEnabled, !history.isEmpty {
            history = []
            persist()
        }
    }

    func isActive(_ patch: BundlePatch) -> Bool {
        activeIDs.contains(patch.productId)
    }

    func record(patch: BundlePatch, activated: Bool, recordHistory: Bool = true) {
        if activated {
            activeIDs.insert(patch.productId)
        } else {
            activeIDs.remove(patch.productId)
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

    /// Turns every option off in the UI and drops leftover apply receipts so a new install starts clean.
    func resetActivations() {
        activeIDs = []
        history = []
        wipePersistedState()
        DevicePatchService.clearApplyReceipts()
        persist()
    }

    private func persist() {
        let snapshot = Snapshot(activeIDs: Array(activeIDs), history: historyEnabled ? history : [])
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
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
    }

    private var fileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            .map { $0.appendingPathComponent("x.patch.activation.json") }
    }

    private func wipePersistedState() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(base as CFDictionary)
    }
}
