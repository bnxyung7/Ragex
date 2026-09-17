import Foundation
import SwiftUI
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
    @Published var showNotificationsSheet: Bool = false
    @Published var toastQueue: [ToastMessage] = []
    @Published var broadcastMessages: [AdminBroadcastMessage] = []
    @Published var activeToast: InAppToastItem? = nil
    
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
        if !notifications.contains(where: { $0.id == -1 }) {
            notifications.insert(expiredNotif, at: 0)
        }
        unreadCount += 1
    }
    
    /// Avisar que queda poco tiempo (llamado desde KeyStore)
    func notifyExpiringSoon(minutesLeft: Int) {
        enqueueToast(
            title: "⚠️ Acceso por vencer",
            message: "Tu membresía expira en \(minutesLeft) minuto\(minutesLeft == 1 ? "" : "s").",
            type: .warning,
            linkURL: nil,
            linkTitle: nil,
            isUrgent: true
        )
    }
    
    /// Limpiar notificación de expiración (llamado al renovar key)
    func resetExpirationNotification() {
        notifications.removeAll { $0.id == -1 }
        updateUnreadCount()
    }
    
    /// Encolar un toast para mostrar en pantalla
    func enqueueToast(title: String, message: String, type: ToastType, linkURL: String?, linkTitle: String?, isUrgent: Bool) {
        let toast = ToastMessage(
            title: title, message: message, type: type,
            linkURL: linkURL, linkTitle: linkTitle, isUrgent: isUrgent
        )
        toastQueue.append(toast)
        if activeToast == nil {
            showNextToast()
        }
    }
    
    /// Mostrar el siguiente toast de la cola
    func showNextToast() {
        guard !toastQueue.isEmpty else { activeToast = nil; return }
        activeToast = toastQueue.removeFirst()
        // Auto-dismiss después de 4 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.dismissToast()
        }
    }
    
    /// Descartar toast activo
    func dismissToast() {
        activeToast = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showNextToast()
        }
    }
    
    /// Insertar un mensaje broadcast (de push remoto)
    func insertBroadcast(_ broadcast: AdminBroadcastMessage, showToast: Bool) {
        broadcastMessages.insert(broadcast, at: 0)
        if showToast {
            enqueueToast(
                title: broadcast.title,
                message: broadcast.message,
                type: broadcast.isUrgent ? .warning : .admin,
                linkURL: broadcast.linkURL,
                linkTitle: broadcast.linkTitle,
                isUrgent: broadcast.isUrgent
            )
        }
    }
}

// MARK: - Toast / Broadcast types (usados por PushNotificationService y vistas)

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

// Alias para la vista InAppToastOverlay
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

// MARK: - API Response Models

private struct NotificationResponse: Codable {
    let success: Bool
    let notifications: [ServerNotification]
}
