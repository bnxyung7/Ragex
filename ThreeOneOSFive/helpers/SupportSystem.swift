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
    static let discordAnnounceURL = "https://discord.gg/wAAbwX8Dmc"
    static let discordSupportURL = "https://discord.gg/wpqqTnfXfc"
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
    var supportTitle: String { text("support.title") }
    var supportSubtitle: String { text("support.subtitle") }
    var supportWhatsAppTitle: String { text("support.whatsapp_title") }
    var supportWhatsAppDesc: String { text("support.whatsapp_desc") }
    var supportTelegramTitle: String { text("support.telegram_title") }
    var supportTelegramDesc: String { text("support.telegram_desc") }
    var supportEmailTitle: String { text("support.email_title") }
    var supportEmailDesc: String { text("support.email_desc") }
    var supportDeveloperTitle: String { text("support.developer_title") }
    var supportDeveloperDesc: String { text("support.developer_desc") }
    var supportOpenButton: String { text("support.open") }
    var supportCopiedMessage: String { text("support.copied") }
}
