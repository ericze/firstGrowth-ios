import SwiftUI

struct SidebarDrawer: View {
    let headerConfig: HomeHeaderConfig
    let babyRepository: BabyRepository
    @Binding var isNavigationAtRoot: Bool
    @Binding var isSidebarOpen: Bool
    let onHeaderTap: () -> Void

    @State private var navigationPath = NavigationPath()
    @State private var proSheetItem: SidebarIndexItem?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SidebarMenuView(
                headerConfig: headerConfig,
                onHeaderTap: onHeaderTap,
                onNavigate: { route in navigationPath.append(route) },
                onProItemTap: { item in proSheetItem = item }
            )
            .navigationDestination(for: SidebarRoute.self) { route in
                switch route {
                case .babyProfile:
                    BabyProfileView(babyRepository: babyRepository)
                case .language:
                    LanguageRegionView()
                }
            }
        }
        .onChange(of: navigationPath) { _, _ in isNavigationAtRoot = navigationPath.isEmpty }
        .onChange(of: isSidebarOpen) { _, newValue in if !newValue { navigationPath = NavigationPath() } }
        .sheet(item: $proSheetItem) { item in
            PaywallSheet(featureTitle: item.title)
        }
        .background(AppTheme.Colors.background)
    }
}

enum SidebarRoute: Hashable {
    case babyProfile
    case language
}

struct SidebarIndexItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let isPro: Bool
    let route: SidebarRoute?

    static let items: [SidebarIndexItem] = [
        SidebarIndexItem(
            id: "profile",
            title: String(localized: "shell.sidebar.profile.title"),
            detail: String(localized: "shell.sidebar.profile.detail"),
            isPro: false,
            route: .babyProfile
        ),
        SidebarIndexItem(
            id: "preferences",
            title: String(localized: "shell.sidebar.preferences.title"),
            detail: String(localized: "shell.sidebar.preferences.detail"),
            isPro: false,
            route: .language
        ),
        SidebarIndexItem(
            id: "family",
            title: String(localized: "shell.sidebar.family.title"),
            detail: String(localized: "shell.sidebar.family.detail"),
            isPro: true,
            route: nil
        ),
        SidebarIndexItem(
            id: "cloud",
            title: String(localized: "shell.sidebar.cloud.title"),
            detail: String(localized: "shell.sidebar.cloud.detail"),
            isPro: true,
            route: nil
        ),
    ]
}
