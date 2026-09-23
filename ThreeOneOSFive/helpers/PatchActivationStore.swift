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
                clearHistory()
            } else {
                persist()
            }
        }
    }

    private let defaultsKey = "x.patch.activation.v1"
    private let historyEnabledKey = "x.patch.activation.history.enabled"
    private let historyLimit = 80
    private let keychainService = "x.patch.activation"
    private let keychainAccount = "snapshot.v1"

    private struct Snapshot: Codable {
        var activeIDs: [String]
        var history: [PatchActivationEvent]
    }

    private init() {
        historyEnabled = UserDefaults.standard.object(forKey: historyEnabledKey) as? Bool ?? false
        load()
        if !historyEnabled, !history.isEmpty {
            clearHistory()
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

    private func persist() {
        let snapshot = Snapshot(activeIDs: Array(activeIDs), history: history)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
        saveKeychain(data)
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
        if data == nil {
            data = readKeychain()
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

    private func readKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    private func saveKeychain(_ data: Data) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }
}
