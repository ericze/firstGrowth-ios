import Foundation

struct SleepSessionRepository {
    private let defaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    nonisolated init(defaults: UserDefaults = .standard, storageKey: String = "active_sleep_session") {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    @discardableResult
    func startSession(startedAt: Date) -> SleepSessionState {
        let session = SleepSessionState(id: UUID(), startedAt: startedAt, isActive: true)
        save(session)
        return session
    }

    func loadActiveSession() -> SleepSessionState? {
        guard
            let data = defaults.data(forKey: storageKey),
            let session = try? decoder.decode(SleepSessionState.self, from: data),
            session.isActive
        else {
            return nil
        }

        return session
    }

    @discardableResult
    func endSession() -> SleepSessionState? {
        let session = loadActiveSession()
        clearSession()
        return session
    }

    func clearSession() {
        defaults.removeObject(forKey: storageKey)
    }

    private func save(_ session: SleepSessionState) {
        guard let data = try? encoder.encode(session) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
