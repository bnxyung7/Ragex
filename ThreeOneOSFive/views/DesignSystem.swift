import SwiftUI

enum AppTheme {
    static var accent: Color {
        ThemeManager.shared.currentTheme.color
    }
    
    static var gradient: LinearGradient {
        ThemeManager.shared.currentTheme.gradient
    }
    
    // MARK: - Colors (Pure Black Theme)
    static let pageBackground = Color.black
    static let cardBackground = Color(hex: "0A0A0A")
    static let cardElevated   = Color(hex: "121212")
    static let cardBorder     = Color(hex: "1E1E1E")
    static let consoleBackground = Color.black
    
    // MARK: - Spacing System (Consistent Spacing Scale)
    static let spacing2: CGFloat = 2
    static let spacing4: CGFloat = 4
    static let spacing6: CGFloat = 6
    static let spacing8: CGFloat = 8
    static let spacing10: CGFloat = 10
    static let spacing12: CGFloat = 12
    static let spacing14: CGFloat = 14
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    
    // MARK: - Layout Constants
    static let pageInset: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let itemSpacing: CGFloat = 12
    static let compactSpacing: CGFloat = 8
    static let tightSpacing: CGFloat = 4
    
    // MARK: - Icon Sizes
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18
    
    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXLarge: CGFloat = 20
    static let contentCardCornerRadius: CGFloat = 18
    
    // MARK: - Legacy (keeping for compatibility)
    static let contentCardInset: CGFloat = 16
    static let contentCardPadding: CGFloat = 16
}

// MARK: - Obsidian Card Modifier (Pure Black)
struct ObsidianCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 18
    var borderColor: Color = AppTheme.cardBorder
    var glowing: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(hex: "0A0A0A"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.8), radius: glowing ? 8 : 4, x: 0, y: 2)
    }
}

extension View {
    func obsidianCard(cornerRadius: CGFloat = 18, borderColor: Color = AppTheme.cardBorder, glowing: Bool = false) -> some View {
        modifier(ObsidianCardModifier(cornerRadius: cornerRadius, borderColor: borderColor, glowing: glowing))
    }
}

// MARK: - Cyber Badge
struct CyberBadge: View {
    let text: String
    var icon: String? = nil
    var color: Color = AppTheme.accent
    
    var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.14))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.35), lineWidth: 0.8)
        )
    }
}

// MARK: - Pulse Status Dot
struct PulseStatusDot: View {
    var color: Color = Color(hex: "10B981")
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 14, height: 14)
                .scaleEffect(isPulsing ? 1.4 : 0.9)
                .opacity(isPulsing ? 0.2 : 0.8)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: isPulsing)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.8), radius: 3)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

struct AppCardBorder: View {
    var body: some View {
        RoundedRectangle(
            cornerRadius: AppTheme.contentCardCornerRadius,
            style: .continuous
        )
        .strokeBorder(
            Color.white.opacity(0.08),
            lineWidth: 0.8
        )
        .accessibilityHidden(true)
    }
}

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(tint.opacity(0.3), lineWidth: 0.8)
                )
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 38)
        .background(
            Color(hex: "13141F"),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        )
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon60x60")
                ?? UIImage(named: "AppIcon")
                ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                ?? Bundle.main.path(forResource: "AppIcon-1024", ofType: "png").flatMap(UIImage.init(contentsOfFile:)) {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(hex: "121216")
                    Image(systemName: "shield.fill")
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}
