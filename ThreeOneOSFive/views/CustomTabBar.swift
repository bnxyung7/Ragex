import SwiftUI
import UIKit

// Slim bottom bar. Icons stay small so every visible section fits,
// and pages stay mounted so switching tabs does not rebuild them.

struct TabBarItemModel: Identifiable {
    let id: Int
    let section: AppSection
    let title: String
    let systemImage: String
    let assetImage: String?
    var badge: Int = 0
}

struct CustomTabBarContainer<Page: View>: View {
    @Binding var selectedTab: Int
    let items: [TabBarItemModel]
    let content: (AppSection) -> Page

    @ObservedObject private var notifService = NotificationService.shared
    @State private var mounted: Set<Int>

    init(
        selectedTab: Binding<Int>,
        items: [TabBarItemModel],
        content: @escaping (AppSection) -> Page
    ) {
        self._selectedTab = selectedTab
        self.items = items
        self.content = content
        self._mounted = State(initialValue: [selectedTab.wrappedValue])
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                ForEach(items) { item in
                    if mounted.contains(item.id) {
                        content(item.section)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(selectedTab == item.id ? 1 : 0)
                            .allowsHitTesting(selectedTab == item.id)
                            .accessibilityHidden(selectedTab != item.id)
                            .zIndex(selectedTab == item.id ? 1 : 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 54)
            }

            CustomTabBar(
                selectedTab: $selectedTab,
                items: items.map { item in
                    var copy = item
                    if copy.section == .profile {
                        copy.badge = notifService.unreadCount
                    }
                    return copy
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .onAppear { mounted.insert(selectedTab) }
        .onChange(of: selectedTab) { mounted.insert($0) }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let items: [TabBarItemModel]

    private static let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    selectTab(item.id)
                } label: {
                    CustomTabBarItem(
                        item: item,
                        isSelected: selectedTab == item.id
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: "101018").opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .onAppear { Self.haptic.prepare() }
    }

    private func selectTab(_ id: Int) {
        guard id != selectedTab else { return }
        selectedTab = id
        Self.haptic.impactOccurred(intensity: 0.45)
        Self.haptic.prepare()
    }
}

private struct CustomTabBarItem: View {
    let item: TabBarItemModel
    let isSelected: Bool

    private var selectedTint: Color { Color(hex: "60A5FA") }
    private var idleTint: Color { Color(hex: "8B8BA3") }

    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .topTrailing) {
                iconView
                    .frame(width: 28, height: 22)

                if item.badge > 0 {
                    Text(item.badge > 9 ? "9+" : "\(item.badge)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 14, minHeight: 14)
                        .background(Color(hex: "EF4444"))
                        .clipShape(Capsule())
                        .offset(x: 8, y: -6)
                }
            }

            Text(item.title)
                .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? selectedTint : idleTint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Capsule()
                .fill(isSelected ? selectedTint : Color.clear)
                .frame(width: 12, height: 2)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var iconView: some View {
        if let assetName = item.assetImage,
           let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .opacity(isSelected ? 1 : 0.72)
        } else {
            Image(systemName: item.systemImage)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? selectedTint : idleTint)
        }
    }
}
