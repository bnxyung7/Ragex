import SwiftUI

// MARK: - App Theme
enum AppThemeColor: String, CaseIterable, Identifiable {
    case orange = "orange"
    case red = "red"
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .orange: return "Naranja"
        case .red: return "Rojo"
        case .blue: return "Azul"
        case .green: return "Verde"
        case .purple: return "Morado"
        }
    }
    
    var color: Color {
        switch self {
        case .orange: return Color(hex: "FF9800")
        case .red: return Color(hex: "F44336")
        case .blue: return Color(hex: "2196F3")
        case .green: return Color(hex: "4CAF50")
        case .purple: return Color(hex: "9C27B0")
        }
    }
    
    var icon: String {
        "circle.fill"
    }
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
        self.currentTheme = AppThemeColor(rawValue: stored ?? "") ?? .orange
    }
    
    func setTheme(_ theme: AppThemeColor) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }
}

// MARK: - Environment Key
private struct ThemeColorEnvironmentKey: EnvironmentKey {
    static let defaultValue: Color = AppThemeColor.orange.color
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
