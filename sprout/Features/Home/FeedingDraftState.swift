import Foundation

enum MilkTab: String, CaseIterable, Identifiable {
    case nursing
    case bottle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nursing:
            String(localized: "home.sheet.milk.title.nursing")
        case .bottle:
            String(localized: "home.sheet.milk.title.bottle")
        }
    }

    var detailTitle: String {
        switch self {
        case .nursing:
            String(localized: "home.sheet.milk.detail.nursing")
        case .bottle:
            String(localized: "home.sheet.milk.detail.bottle")
        }
    }
}

enum NursingSide: String, CaseIterable, Identifiable {
    case left
    case right

    var id: String { rawValue }

    var title: String {
        switch self {
        case .left:
            String(localized: "home.sheet.nursing.side.left")
        case .right:
            String(localized: "home.sheet.nursing.side.right")
        }
    }

    var badge: String {
        switch self {
        case .left:
            "L"
        case .right:
            "R"
        }
    }
}

struct FeedingDraftState {
    static let presets = [90, 120, 150, 180]
    static let bottleMinimum = 0
    static let bottleMaximum = 300
    static let bottleStep = 10

    var selectedTab: MilkTab = .nursing
    var leftAccumulatedSeconds: Int = 0
    var rightAccumulatedSeconds: Int = 0
    var activeSide: NursingSide?
    var activeStartDate: Date?
    var bottleAmountMl: Int = 0

    var selectedBottlePreset: Int? {
        Self.presets.contains(bottleAmountMl) ? bottleAmountMl : nil
    }

    mutating func selectTab(_ tab: MilkTab) {
        selectedTab = tab
    }

    mutating func tapNursing(side: NursingSide, now: Date) {
        if activeSide == side {
            pauseActiveSide(now: now)
            return
        }

        pauseActiveSide(now: now)
        activeSide = side
        activeStartDate = now
    }

    mutating func pauseActiveSide(now: Date) {
        guard let side = activeSide, let start = activeStartDate else { return }

        let delta = max(0, Int(now.timeIntervalSince(start)))
        switch side {
        case .left:
            leftAccumulatedSeconds += delta
        case .right:
            rightAccumulatedSeconds += delta
        }

        activeSide = nil
        activeStartDate = nil
    }

    func displayedSeconds(for side: NursingSide, now: Date) -> Int {
        let baseSeconds: Int
        switch side {
        case .left:
            baseSeconds = leftAccumulatedSeconds
        case .right:
            baseSeconds = rightAccumulatedSeconds
        }

        guard activeSide == side, let start = activeStartDate else {
            return baseSeconds
        }

        return baseSeconds + max(0, Int(now.timeIntervalSince(start)))
    }

    func totalNursingSeconds(now: Date) -> Int {
        displayedSeconds(for: .left, now: now) + displayedSeconds(for: .right, now: now)
    }

    func canSubmit(now: Date) -> Bool {
        totalNursingSeconds(now: now) > 0 || bottleAmountMl > 0
    }

    mutating func selectBottlePreset(_ preset: Int) {
        bottleAmountMl = min(max(preset, Self.bottleMinimum), Self.bottleMaximum)
    }

    mutating func increaseBottle() {
        bottleAmountMl = min(bottleAmountMl + Self.bottleStep, Self.bottleMaximum)
    }

    mutating func decreaseBottle() {
        bottleAmountMl = max(bottleAmountMl - Self.bottleStep, Self.bottleMinimum)
    }

    mutating func reset() {
        self = FeedingDraftState()
    }

    func floorMinutes(_ seconds: Int) -> Int {
        max(0, seconds / 60)
    }
}
