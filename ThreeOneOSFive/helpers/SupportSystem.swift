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
    var supportTitle: String {
        switch self {
        case .spanish: return "Soporte"
        case .english: return "Support"
        case .portuguese: return "Suporte"
        }
    }

    var supportSubtitle: String {
        switch self {
        case .spanish: return "Estamos aquí para ayudarte"
        case .english: return "We're here to help you"
        case .portuguese: return "Estamos aqui para ajudar você"
        }
    }

    var supportWhatsAppTitle: String {
        switch self {
        case .spanish: return "Soporte WhatsApp"
        case .english: return "WhatsApp Support"
        case .portuguese: return "Suporte WhatsApp"
        }
    }

    var supportWhatsAppDesc: String {
        switch self {
        case .spanish: return "Habla con nosotros directamente"
        case .english: return "Chat with us directly"
        case .portuguese: return "Fale conosco diretamente"
        }
    }

    var supportTelegramTitle: String {
        switch self {
        case .spanish: return "Soporte Telegram"
        case .english: return "Telegram Support"
        case .portuguese: return "Suporte Telegram"
        }
    }

    var supportTelegramDesc: String {
        switch self {
        case .spanish: return "Respuestas rápidas en Telegram"
        case .english: return "Fast responses on Telegram"
        case .portuguese: return "Respostas rápidas no Telegram"
        }
    }

    var supportEmailTitle: String {
        switch self {
        case .spanish: return "Soporte por correo"
        case .english: return "Email Support"
        case .portuguese: return "Suporte por e-mail"
        }
    }

    var supportEmailDesc: String {
        switch self {
        case .spanish: return "Envíanos un correo"
        case .english: return "Send us an email"
        case .portuguese: return "Envie-nos um e-mail"
        }
    }

    var supportDeveloperTitle: String {
        switch self {
        case .spanish: return "Información del desarrollador"
        case .english: return "Developer Info"
        case .portuguese: return "Informações do desenvolvedor"
        }
    }

    var supportDeveloperDesc: String {
        switch self {
        case .spanish: return "Creado por Bnxyung7"
        case .english: return "Created by Bnxyung7"
        case .portuguese: return "Criado por Bnxyung7"
        }
    }

    var supportOpenButton: String {
        switch self {
        case .spanish: return "Abrir"
        case .english: return "Open"
        case .portuguese: return "Abrir"
        }
    }

    var supportCopiedMessage: String {
        switch self {
        case .spanish: return "Copiado al portapapeles"
        case .english: return "Copied to clipboard!"
        case .portuguese: return "Copiado para a área de transferência"
        }
    }
}
