import SwiftUI

// MARK: - App Theme Color
enum AppThemeColor: String, CaseIterable, Identifiable {
    case purple = "purple"
    case cyan = "cyan"
    case emerald = "emerald"
    case blue = "blue"
    case orange = "orange"
    case red = "red"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .purple: return "Cyber Violet"
        case .cyan: return "Neon Cyan"
        case .emerald: return "Esmeralda"
        case .blue: return "Cobalto"
        case .orange: return "Sunset"
        case .red: return "Crimson"
        }
    }
    
    var color: Color {
        switch self {
        case .purple: return Color(hex: "8B5CF6")
        case .cyan: return Color(hex: "06B6D4")
        case .emerald: return Color(hex: "10B981")
        case .blue: return Color(hex: "3B82F6")
        case .orange: return Color(hex: "F97316")
        case .red: return Color(hex: "EF4444")
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .purple: return Color(hex: "6366F1")
        case .cyan: return Color(hex: "0284C7")
        case .emerald: return Color(hex: "059669")
        case .blue: return Color(hex: "1D4ED8")
        case .orange: return Color(hex: "EA580C")
        case .red: return Color(hex: "DC2626")
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var icon: String {
        "circle.fill"
    }
}

// MARK: - Global Cyber Colors
struct AppColors {
    static let obsidian = Color(hex: "08080C")
    static let cardBackground = Color(hex: "11121A")
    static let cardElevated = Color(hex: "181926")
    static let cardBorder = Color(hex: "272838")
    static let subtleText = Color(hex: "94A3B8")
    static let neonGlow = Color(hex: "8B5CF6").opacity(0.3)
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppThemeColor {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appThemeColor")
        }
    }
    
    private init() {
        let stored = UserDefaults.standard.string(forKey: "appThemeColor")
        self.currentTheme = AppThemeColor(rawValue: stored ?? "") ?? .purple
    }
    
    func setTheme(_ theme: AppThemeColor) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }
}

// MARK: - Environment Key
private struct ThemeColorEnvironmentKey: EnvironmentKey {
    static let defaultValue: Color = AppThemeColor.purple.color
}

extension EnvironmentValues {
    var themeColor: Color {
        get { self[ThemeColorEnvironmentKey.self] }
        set { self[ThemeColorEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    func themeColor(_ color: Color) -> some View {
        environment(\.themeColor, color)
    }
}
