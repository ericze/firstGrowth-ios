import Foundation

struct GrowthMetricPreferenceStore {
    private let defaults: UserDefaults
    private let storageKey: String

    nonisolated init(
        defaults: UserDefaults = .standard,
        storageKey: String = "growth.metric.preference"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func load() -> GrowthMetric? {
        guard let rawValue = defaults.string(forKey: storageKey) else { return nil }
        return GrowthMetric(rawValue: rawValue)
    }

    func save(_ metric: GrowthMetric) {
        defaults.set(metric.rawValue, forKey: storageKey)
    }
}
