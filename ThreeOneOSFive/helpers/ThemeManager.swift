import SwiftUI

// MARK: - App Theme Color (Pure Black & Monochrome)
enum AppThemeColor: String, CaseIterable, Identifiable {
    case silver = "silver"

    var id: String { rawValue }

    var displayName: String { "Negro Puro" }

    var color: Color {
        Color.white
    }

    var secondaryColor: Color {
        Color(hex: "94A3B8")
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color(hex: "94A3B8")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var icon: String { "circle.fill" }
}

// MARK: - Global Pure Black Colors
struct AppColors {
    static let obsidian       = Color.black
    static let cardBackground = Color(hex: "0A0A0A")
    static let cardElevated   = Color(hex: "121212")
    static let cardBorder     = Color(hex: "1E1E1E")
    static let subtleText     = Color(hex: "64748B")
    static let neonGlow       = Color.white.opacity(0.08)
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppThemeColor = .silver

    private init() {
        self.currentTheme = .silver
    }

    func setTheme(_ theme: AppThemeColor) {
        currentTheme = .silver
    }
}

// MARK: - Environment Key
private struct ThemeColorEnvironmentKey: EnvironmentKey {
    static let defaultValue: Color = Color.white
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
