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
    
    private let baseURL: String
    private let readNotificationsKey = "com.ragex.readNotifications"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // TODO: Cambiar a tu servidor en producción
        self.baseURL = "http://localhost:3000/api"
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
}

// MARK: - API Response Models

private struct NotificationResponse: Codable {
    let success: Bool
    let notifications: [ServerNotification]
}
