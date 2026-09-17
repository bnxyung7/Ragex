import Foundation
import Combine

/// Modelo de notificación del servidor
struct ServerNotification: Codable, Identifiable {
    let id: Int
    let title: String
    let message: String
    let type: String // 'info', 'success', 'warning', 'error'
    let targetUsers: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, message, type
        case targetUsers = "target_users"
        case createdAt = "created_at"
    }
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAt) / 1000)
    }
    
    var icon: String {
        switch type {
        case "success": return "✅"
        case "warning": return "⚠️"
        case "error": return "❌"
        default: return "ℹ️"
        }
    }
}

/// Servicio de notificaciones conectado al panel admin
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var notifications: [ServerNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var showNotificationsSheet: Bool = false // para ProfileView
    
    private let baseURL: String
    private let readNotificationsKey = "com.ragex.readNotifications"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.baseURL = "https://xkeyapi.onrender.com/api"
        loadReadStatus()
    }
    
    /// Obtener notificaciones activas del servidor
    func fetchNotifications() {
        guard let url = URL(string: "\(baseURL)/notifications/active") else { return }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data,
                      error == nil,
                      let response = try? JSONDecoder().decode(NotificationResponse.self, from: data),
                      response.success else {
                    print("[NotificationService] ❌ Error fetching notifications")
                    return
                }
                
                self?.notifications = response.notifications
                self?.updateUnreadCount()
                print("[NotificationService] ✅ Loaded \(response.notifications.count) notifications")
            }
        }.resume()
    }
    
    /// Marcar notificación como leída
    func markAsRead(_ notificationId: Int) {
        var readIds = getReadNotificationIds()
        readIds.insert(notificationId)
        saveReadNotificationIds(readIds)
        updateUnreadCount()
    }
    
    /// Marcar todas como leídas
    func markAllAsRead() {
        let allIds = Set(notifications.map { $0.id })
        saveReadNotificationIds(allIds)
        updateUnreadCount()
    }
    
    /// Verificar si una notificación está leída
    func isRead(_ notificationId: Int) -> Bool {
        getReadNotificationIds().contains(notificationId)
    }
    
    // MARK: - Private
    
    private func updateUnreadCount() {
        let readIds = getReadNotificationIds()
        unreadCount = notifications.filter { !readIds.contains($0.id) }.count
    }
    
    private func getReadNotificationIds() -> Set<Int> {
        if let data = UserDefaults.standard.data(forKey: readNotificationsKey),
           let ids = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            return ids
        }
        return []
    }
    
    private func saveReadNotificationIds(_ ids: Set<Int>) {
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: readNotificationsKey)
        }
    }
    
    private func loadReadStatus() {
        updateUnreadCount()
    }
    
    /// Notificar al usuario que su key expiró (llamado desde KeyStore)
    func notifyExpired() {
        let expiredNotif = ServerNotification(
            id: -1,
            title: "Tu acceso expiró",
            message: "Tu membresía ha vencido. Renueva tu key para seguir usando Free Fire y FF MAX.",
            type: "warning",
            targetUsers: "expired",
            createdAt: Int(Date().timeIntervalSince1970 * 1000)
        )
        // Insertar al inicio si no existe ya
        if !notifications.contains(where: { $0.id == -1 }) {
            notifications.insert(expiredNotif, at: 0)
        }
        unreadCount += 1
    }
}

// MARK: - API Response Models

private struct NotificationResponse: Codable {
    let success: Bool
    let notifications: [ServerNotification]
}
