import SwiftUI
import UIKit

// MARK: - CustomTabBar
//
// Fully custom SwiftUI tab bar that bypasses UITabBar entirely.
// This is the only reliable way to show real PNG logos (Free Fire,
// FF MAX) without iOS converting them to template/monochrome.
//
// Architecture:
//   CustomTabBarContainer  – manages selected tab state + content area
//   CustomTabBar           – the bar itself (pills, icons, labels)
//   CustomTabBarItem       – individual tab item

// MARK: - Item Model

struct TabBarItemModel: Identifiable {
    let id: Int
    let section: AppSection
    let title: String
    /// SF Symbol name used for standard tabs
    let systemImage: String
    /// Asset catalog name for image-based tabs (FF, FF MAX)
    let assetImage: String?
    /// Badge count (notifications etc.)
    var badge: Int = 0
}

// MARK: - CustomTabBarContainer

struct CustomTabBarContainer: View {
    @Binding var selectedTab: Int
    let items: [TabBarItemModel]
    let content: (AppSection) -> AnyView

    @ObservedObject private var notifService = NotificationService.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            // Page content — fills entire screen including under the tab bar
            content(AppSection(rawValue: selectedTab) ?? .home)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Add bottom padding so scroll content clears the tab bar
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: tabBarHeight)
                }

            // Custom tab bar floats at bottom
            CustomTabBar(
                selectedTab: $selectedTab,
                items: items.map { item in
                    var i = item
                    if i.section == .profile {
                        i.badge = notifService.unreadCount
                    }
                    return i
                }
            )
        }
        .ignoresSafeArea(.keyboard)
    }

    private var tabBarHeight: CGFloat { 72 }
}

// MARK: - CustomTabBar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let items: [TabBarItemModel]

    @Environment(\.colorScheme) private var colorScheme
    @State private var pressedTab: Int? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(items) { item in
                CustomTabBarItem(
                    item: item,
                    isSelected: selectedTab == item.id,
                    isPressed: pressedTab == item.id
                )
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectTab(item.id)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in pressedTab = item.id }
                        .onEnded   { _ in pressedTab = nil    }
                )
            }
        }
        .padding(.horizontal, AppTheme.spacing12)
        .padding(.top, AppTheme.spacing10)
        .padding(.bottom, bottomPadding)
        .background(
            ZStack {
                BlurView(style: .systemUltraThinMaterialDark)
                Color(hex: "06060E").opacity(0.82)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.white.opacity(0.03),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, AppTheme.spacing16)
        .padding(.bottom, bottomPaddingOuter)
    }

    private var bottomPadding: CGFloat {
        let inset = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first?.safeAreaInsets.bottom ?? 0)
        return inset > 0 ? max(inset - 16, 4) : 8
    }
    
    private var bottomPaddingOuter: CGFloat {
        let inset = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first?.safeAreaInsets.bottom ?? 0)
        return inset > 0 ? 8 : 12
    }

    private func selectTab(_ id: Int) {
        guard id != selectedTab else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            selectedTab = id
        }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred(intensity: 0.7)
    }
}

// MARK: - CustomTabBarItem

private struct CustomTabBarItem: View {
    let item: TabBarItemModel
    let isSelected: Bool
    let isPressed: Bool

    @State private var appeared = false

    var body: some View {
        VStack(spacing: AppTheme.spacing4) {
            ZStack(alignment: .topTrailing) {
                // Selected pill background
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppTheme.accent.opacity(0.50), lineWidth: 1)
                        )
                        .frame(width: 54, height: 34)
                        .shadow(color: AppTheme.accent.opacity(0.40), radius: 8, x: 0, y: 2)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Color.clear.frame(width: 54, height: 34)
                }

                // Icon
                iconView
                    .frame(width: 54, height: 34)
                    .scaleEffect(isPressed ? 0.90 : (isSelected ? 1.05 : 1.0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)

                // Badge
                if item.badge > 0 {
                    Text(item.badge > 9 ? "9+" : "\(item.badge)")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .frame(minWidth: 14, minHeight: 14)
                        .padding(.horizontal, 3)
                        .background(Color(hex: "EF4444"))
                        .clipShape(Capsule())
                        .offset(x: 4, y: -4)
                }
            }

            // Label
            Text(item.title)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? AppTheme.accent : Color(hex: "5A5A72"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .padding(.vertical, AppTheme.spacing4)
    }

    @ViewBuilder
    private var iconView: some View {
        if let assetName = item.assetImage,
           let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .renderingMode(.original)
                .interpolation(.high)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .opacity(isSelected ? 1.0 : 0.55)
                .saturation(isSelected ? 1.0 : 0.4)
        } else {
            if #available(iOS 17, *) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.accent : Color(hex: "5A5A72"))
                    .symbolEffect(.bounce, value: isSelected)
            } else {
                Image(systemName: item.systemImage)
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.accent : Color(hex: "5A5A72"))
            }
        }
    }
}

// MARK: - BlurView (UIKit bridge)

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
