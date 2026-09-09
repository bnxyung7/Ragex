import Foundation

/// Key duration types
enum KeyDuration: String, Codable, CaseIterable {
    case oneHour = "1H"
    case threeHours = "3H"
    case oneDay = "1D"
    case threeDays = "3D"
    case fifteenDays = "15D"
    case thirtyDays = "30D"
    case sixtyDays = "60D"
    case permanent = "Permanente"
    
    var displayName: String {
        return rawValue
    }
    
    var timeInterval: TimeInterval? {
        switch self {
        case .oneHour: return 3600
        case .threeHours: return 3600 * 3
        case .oneDay: return 86400
        case .threeDays: return 86400 * 3
        case .fifteenDays: return 86400 * 15
        case .thirtyDays: return 86400 * 30
        case .sixtyDays: return 86400 * 60
        case .permanent: return nil
        }
    }
}

/// Status of a key
enum KeyStatus: String, Codable {
    case active = "Activa"
    case expired = "Expirada"
    case banned = "Baneada"
    
    var displayName: String {
        return rawValue
    }
}

/// Key notification types
enum KeyNotification: Codable {
    case reset
    case timeAdded(days: Int)
    case timeReduced(days: Int)
    case banned(reason: String?)
    case unbanned
    case expiring(hoursLeft: Int)
    
    var message: String {
        switch self {
        case .reset:
            return "Tu Key ha sido reiniciada. El tiempo de expiración se ha restablecido."
        case .timeAdded(let days):
            return "Se han añadido \(days) día(s) adicionales a tu Key."
        case .timeReduced(let days):
            return "Se han reducido \(days) día(s) de tu Key."
        case .banned(let reason):
            if let reason = reason {
                return "Tu Key ha sido baneada. Razón: \(reason)"
            }
            return "Tu Key ha sido baneada por el administrador."
        case .unbanned:
            return "Tu Key ha sido desbaneada. Ya puedes usarla nuevamente."
        case .expiring(let hours):
            return "Tu Key expirará en \(hours) hora(s). Renueva pronto."
        }
    }
    
    var icon: String {
        switch self {
        case .reset: return "arrow.clockwise.circle.fill"
        case .timeAdded: return "plus.circle.fill"
        case .timeReduced: return "minus.circle.fill"
        case .banned: return "xmark.shield.fill"
        case .unbanned: return "checkmark.shield.fill"
        case .expiring: return "clock.badge.exclamationmark.fill"
        }
    }
    
    var color: String {
        switch self {
        case .reset: return "blue"
        case .timeAdded: return "green"
        case .timeReduced: return "orange"
        case .banned: return "red"
        case .unbanned: return "green"
        case .expiring: return "yellow"
        }
    }
}

/// User Key model
struct UserKey: Codable, Identifiable {
    let id: UUID
    let keyString: String
    let duration: KeyDuration
    let createdAt: Date
    var expiresAt: Date?
    var userName: String?
    var isBanned: Bool
    var banReason: String?
    var notifications: [KeyNotification]
    
    init(keyString: String, duration: KeyDuration, userName: String? = nil) {
        self.id = UUID()
        self.keyString = keyString
        self.duration = duration
        self.createdAt = Date()
        self.userName = userName
        self.isBanned = false
        self.banReason = nil
        self.notifications = []
        
        if let interval = duration.timeInterval {
            self.expiresAt = Date().addingTimeInterval(interval)
        } else {
            self.expiresAt = nil // Permanent
        }
    }
    
    /// Check if key is expired
    var isExpired: Bool {
        guard let expiresAt = expiresAt else {
            return false // Permanent keys never expire
        }
        return Date() > expiresAt
    }
    
    /// Current status
    var status: KeyStatus {
        if isBanned {
            return .banned
        }
        return isExpired ? .expired : .active
    }
    
    /// Check if key is valid (not banned and not expired)
    var isValid: Bool {
        return !isBanned && !isExpired
    }
    
    /// Time remaining as string
    var timeRemaining: String {
        if isBanned {
            return "Baneada"
        }
        
        guard let expiresAt = expiresAt else {
            return "Permanente"
        }
        
        if isExpired {
            return "Expirada"
        }
        
        let interval = expiresAt.timeIntervalSince(Date())
        let days = Int(interval / 86400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Format expiration date
    var expirationDateString: String {
        guard let expiresAt = expiresAt else {
            return "Nunca"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: expiresAt)
    }
}

/// Active user session
struct UserSession: Codable {
    let key: UserKey
    let activatedAt: Date
    
    var isValid: Bool {
        return !key.isExpired
    }
}
