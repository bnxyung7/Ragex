import Foundation
import SwiftUI
import Combine

// MARK: - Toast / Broadcast types

enum ToastType {
    case info, success, warning, error, admin

    var color: Color {
        switch self {
        case .info:    return Color(hex: "3B82F6")
        case .success: return Color(hex: "22C55E")
        case .warning: return Color(hex: "F59E0B")
        case .error:   return Color(hex: "EF4444")
        case .admin:   return Color(hex: "A855F7")
        }
    }

    var icon: String {
        switch self {
        case .info:    return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.circle.fill"
        case .admin:   return "megaphone.fill"
        }
    }

    var badgeText: String {
        switch self {
        case .info:    return "INFO"
        case .success: return "OK"
        case .warning: return "AVISO"
        case .error:   return "ERROR"
        case .admin:   return "ADMIN"
        }
    }
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let type: ToastType
    let linkURL: String?
    let linkTitle: String?
    let isUrgent: Bool
}

typealias InAppToastItem = ToastMessage

struct AdminBroadcastMessage: Identifiable {
    let id: String
    let title: String
    let message: String
    let timestamp: String
    let linkURL: String?
    let linkTitle: String?
    let isUrgent: Bool
}

// MARK: - Server Notification model

struct ServerNotification: Codable, Identifiable {
    let id: Int
    let title: String
    let message: String
    let type: String           // info, warning, success, update
    let priority: String       // low, normal, high, urgent
    let link: String
    let imageUrl: String
    let actionButton: String
    let actionUrl: String
    let targetAudience: String
    let targetDevices: String
    let isActive: Bool
    let expiresAt: String?
    let createdAt: String
    let createdBy: String
    let viewCount: Int
    let clickCount: Int

    enum CodingKeys: String, CodingKey {
        case id, title, message, type, priority, link
        case imageUrl, actionButton, actionUrl
        case targetAudience, targetDevices, isActive
        case expiresAt, createdAt, createdBy
        case viewCount, clickCount
    }

    var date: Date { 
        if let timestamp = Double(createdAt.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: "").prefix(19)) {
            return Date(timeIntervalSince1970: timestamp)
        }
        return Date()
    }

    var icon: String {
        switch type {
        case "success": return "✅"
        case "warning": return "⚠️"
        case "error":   return "❌"
        case "update":  return "🔄"
        default:        return "ℹ️"
        }
    }
    
    var badgeColor: Color {
        switch type {
        case "success": return Color(hex: "22C55E")
        case "warning": return Color(hex: "F59E0B")
        case "error":   return Color(hex: "EF4444")
        case "update":  return Color(hex: "3B82F6")
        default:        return Color(hex: "3B82F6")
        }
    }
    
    var priorityBadgeColor: Color {
        switch priority {
        case "urgent":  return Color(hex: "EF4444")
        case "high":    return Color(hex: "F59E0B")
        case "normal":  return Color(hex: "3B82F6")
        case "low":     return Color(hex: "6B7280")
        default:        return Color(hex: "3B82F6")
        }
    }
    
    var targetUsers: String { targetAudience } // Backward compatibility
}

// MARK: - NotificationService

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    // Publicados
    @Published var notifications: [ServerNotification] = []
    @Published var broadcastMessages: [AdminBroadcastMessage] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var showNotificationsSheet: Bool = false
    @Published var toastQueue: [ToastMessage] = []
    @Published var activeToast: InAppToastItem? = nil
    @Published var readMessageIDs: Set<String> = []   // broadcast IDs leídos (String)

    private let baseURL = "https://xkeyapi.onrender.com/api"
    private let readServerNotifsKey = "com.ragex.readNotifications"  // Int IDs

    private init() {
        loadReadStatus()
    }

    // MARK: - Fetch

    func fetchNotifications() {
        // Get device ID (hardware ID)
        let deviceId: String
        if let uuid = UIDevice.current.identifierForVendor {
            deviceId = uuid.uuidString
        } else {
            let key = "com.x.deviceId"
            if let stored = UserDefaults.standard.string(forKey: key) {
                deviceId = stored
            } else {
                let newId = UUID().uuidString
                UserDefaults.standard.set(newId, forKey: key)
                deviceId = newId
            }
        }
        
        let urlString = deviceId.isEmpty 
            ? "\(baseURL)/notifications/active"
            : "\(baseURL)/notifications/active?deviceId=\(deviceId)"
        
        guard let url = URL(string: urlString) else { return }
        isLoading = true
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let data = data,
                      let resp = try? JSONDecoder().decode(NotificationResponse.self, from: data),
                      resp.success else { return }
                self?.notifications = resp.notifications
                self?.recalcUnread()
            }
        }.resume()
    }

    @MainActor
    func fetchAdminBroadcasts() async {
        fetchNotifications()
    }
    
    // MARK: - Track notification view
    
    func trackNotificationView(_ notificationId: Int) {
        guard let url = URL(string: "\(baseURL)/notifications/\(notificationId)/view") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request).resume()
    }
    
    // MARK: - Track notification click
    
    func trackNotificationClick(_ notificationId: Int) {
        guard let url = URL(string: "\(baseURL)/notifications/\(notificationId)/click") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request).resume()
    }

    // MARK: - Mark as read

    /// ServerNotification (Int ID)
    func markAsRead(_ notificationId: Int) {
        var ids = getReadServerIDs()
        ids.insert(notificationId)
        saveReadServerIDs(ids)
        trackNotificationView(notificationId)  // Track view on server
        recalcUnread()
    }

    /// AdminBroadcastMessage (String ID) — llamado con label `id:`
    func markAsRead(id: String) {
        readMessageIDs.insert(id)
        recalcUnread()
    }

    func markAllAsRead() {
        saveReadServerIDs(Set(notifications.map { $0.id }))
        readMessageIDs = readMessageIDs.union(Set(broadcastMessages.map { $0.id }))
        recalcUnread()
    }

    func isRead(_ notificationId: Int) -> Bool {
        getReadServerIDs().contains(notificationId)
    }

    // MARK: - Toast queue

    func enqueueToast(title: String, message: String, type: ToastType,
                      linkURL: String?, linkTitle: String?, isUrgent: Bool) {
        let toast = ToastMessage(title: title, message: message, type: type,
                                 linkURL: linkURL, linkTitle: linkTitle, isUrgent: isUrgent)
        toastQueue.append(toast)
        if activeToast == nil { showNextToast() }
    }

    func showNextToast() {
        guard !toastQueue.isEmpty else { activeToast = nil; return }
        activeToast = toastQueue.removeFirst()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in self?.dismissToast() }
    }

    func dismissToast() {
        activeToast = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.showNextToast() }
    }

    // MARK: - Broadcast insert

    func insertBroadcast(_ broadcast: AdminBroadcastMessage, showToast: Bool) {
        broadcastMessages.insert(broadcast, at: 0)
        if showToast {
            enqueueToast(title: broadcast.title, message: broadcast.message,
                         type: broadcast.isUrgent ? .warning : .admin,
                         linkURL: broadcast.linkURL, linkTitle: broadcast.linkTitle,
                         isUrgent: broadcast.isUrgent)
        }
    }

    // MARK: - Key expiry helpers (llamados desde KeyStore)

    func notifyExpired() {
        let notif = ServerNotification(
            id: -1,
            title: "Tu acceso expiró",
            message: "Tu membresía ha vencido. Renueva tu key para seguir usando Free Fire y FF MAX.",
            type: "warning",
            priority: "high",
            link: "",
            imageUrl: "",
            actionButton: "",
            actionUrl: "",
            targetAudience: "all",
            targetDevices: "",
            isActive: true,
            expiresAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            createdBy: "system",
            viewCount: 0,
            clickCount: 0
        )
        if !notifications.contains(where: { $0.id == -1 }) {
            notifications.insert(notif, at: 0)
        }
        recalcUnread()
    }

    func notifyExpiringSoon(minutesLeft: Int) {
        enqueueToast(
            title: "⚠️ Acceso por vencer",
            message: "Tu membresía expira en \(minutesLeft) minuto\(minutesLeft == 1 ? "" : "s").",
            type: .warning, linkURL: nil, linkTitle: nil, isUrgent: true
        )
    }

    func resetExpirationNotification() {
        notifications.removeAll { $0.id == -1 }
        recalcUnread()
    }

    // MARK: - Private

    private func recalcUnread() {
        let readServer = getReadServerIDs()
        let u1 = notifications.filter { !readServer.contains($0.id) }.count
        let u2 = broadcastMessages.filter { !readMessageIDs.contains($0.id) }.count
        unreadCount = u1 + u2
    }

    private func getReadServerIDs() -> Set<Int> {
        guard let data = UserDefaults.standard.data(forKey: readServerNotifsKey),
              let ids = try? JSONDecoder().decode(Set<Int>.self, from: data) else { return [] }
        return ids
    }

    private func saveReadServerIDs(_ ids: Set<Int>) {
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: readServerNotifsKey)
        }
    }

    private func loadReadStatus() { recalcUnread() }
}

// MARK: - API Response

private struct NotificationResponse: Codable {
    let success: Bool
    let notifications: [ServerNotification]
}
