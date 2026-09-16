import SwiftUI

// MARK: - Support Models
struct SupportCategory: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: String
    let descriptionKey: String
    let color: Color
    let action: SupportAction
}

enum SupportAction {
    case whatsapp
    case telegram
    case email
}

struct SupportContact {
    static let whatsappNumber = "+18099289722"
    static let telegramUsername = "Bnxyung7"
    static let email = "support@xapp.com"
    static let developerName = "Bnxyung7"
}

// MARK: - Support Theme Colors
struct SupportTheme {
    static let primary = Color(hex: "4CAF50") // Verde
    static let secondary = Color(hex: "2196F3") // Azul
    static let accent = Color(hex: "FF9800") // Naranja
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Support Localizations
extension AppLanguage {
    // Support screen
    var supportTitle: String {
        switch self {
        case .english: return "Support"
        }
    }
    
    var supportSubtitle: String {
        switch self {
        case .english: return "We're here to help you"
        }
    }
    
    var supportWhatsAppTitle: String {
        switch self {
        case .english: return "WhatsApp Support"
        }
    }
    
    var supportWhatsAppDesc: String {
        switch self {
        case .english: return "Chat with us directly"
        }
    }
    
    var supportTelegramTitle: String {
        switch self {
        case .english: return "Telegram Support"
        }
    }
    
    var supportTelegramDesc: String {
        switch self {
        case .english: return "Fast responses on Telegram"
        }
    }
    
    var supportEmailTitle: String {
        switch self {
        case .english: return "Email Support"
        }
    }
    
    var supportEmailDesc: String {
        switch self {
        case .english: return "Send us an email"
        }
    }
    
    var supportDeveloperTitle: String {
        switch self {
        case .english: return "Developer Info"
        }
    }
    
    var supportDeveloperDesc: String {
        switch self {
        case .english: return "Created by Bnxyung7"
        }
    }
    
    var supportOpenButton: String {
        switch self {
        case .english: return "Open"
        }
    }
    
    var supportCopiedMessage: String {
        switch self {
        case .english: return "Copied to clipboard!"
        }
    }
}
