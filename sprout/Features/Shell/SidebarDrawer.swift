import SwiftUI

struct SidebarDrawer: View {
    let headerConfig: HomeHeaderConfig
    let babyRepository: BabyRepository
    @Binding var isNavigationAtRoot: Bool
    @Binding var isSidebarOpen: Bool

    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SidebarMenuView(
                headerConfig: headerConfig,
                onHeaderTap: { navigationPath.append(SidebarRoute.babyProfile) },
                onNavigate: { route in navigationPath.append(route) }
            )
            .navigationDestination(for: SidebarRoute.self) { route in
                switch route {
                case .babyProfile:
                    BabyProfileView(babyRepository: babyRepository)
                case .language:
                    LanguageRegionView(onLanguageChange: { newLanguage in
                        AppLanguageManager.shared.language = newLanguage
                    })
                }
            }
        }
        .onChange(of: navigationPath) { _, _ in isNavigationAtRoot = navigationPath.isEmpty }
        .onChange(of: isSidebarOpen) { _, newValue in
            if !newValue {
                navigationPath = NavigationPath()
            }
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
    let route: SidebarRoute

    static var items: [SidebarIndexItem] {
        let service = LocalizationService.current

        return [
            SidebarIndexItem(
                id: "language",
                title: service.string(
                    forKey: "shell.sidebar.language.title",
                    fallback: "Language & Region"
                ),
                detail: service.string(
                    forKey: "shell.sidebar.language.detail",
                    fallback: "Display language and timezone"
                ),
                route: .language
            ),
        ]
    }
}
