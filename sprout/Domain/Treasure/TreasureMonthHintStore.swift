import Foundation

struct TreasureMonthHintStore {
    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "treasure.month_hint.has_shown"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func hasShownHint() -> Bool {
        defaults.bool(forKey: storageKey)
    }

    func markShown() {
        defaults.set(true, forKey: storageKey)
    }
}
