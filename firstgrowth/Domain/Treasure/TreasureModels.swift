import CoreGraphics
import Foundation

enum TreasureFilter: String, CaseIterable, Identifiable {
    case allMemories
    case starredMoments
    case timeLetters

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allMemories:
            "全部记忆"
        case .starredMoments:
            "⭐ 星标时刻"
        case .timeLetters:
            "✉️ 时光信笺"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .allMemories:
            "查看全部记忆"
        case .starredMoments:
            "查看星标时刻"
        case .timeLetters:
            "查看时光信笺"
        }
    }
}

enum WeeklyLetterDensity: String, Codable, CaseIterable {
    case silent
    case normal
    case dense
}

enum TreasureTimelineItemType: Equatable {
    case memory
    case milestone
    case weeklyLetterSilent
    case weeklyLetterNormal
    case weeklyLetterDense
}

struct TreasureTimelineItem: Identifiable, Equatable {
    let id: UUID
    let type: TreasureTimelineItemType
    let createdAt: Date
    let monthKey: String
    let ageInDays: Int?
    let imageLocalPath: String?
    let note: String?
    let hasImageLoadError: Bool
    let isMilestone: Bool
    let letterDensity: WeeklyLetterDensity?
    let collapsedText: String?
    let expandedText: String?
    let weekStart: Date?
    let weekEnd: Date?

    var isWeeklyLetter: Bool {
        letterDensity != nil
    }

    var canOpenWeeklyLetter: Bool {
        type == .weeklyLetterNormal || type == .weeklyLetterDense
    }
}

struct TreasureMonthAnchor: Identifiable, Equatable {
    let id: String
    let monthKey: String
    let displayText: String
    let firstTimelineItemID: UUID
}

struct TreasureComposeDraft: Equatable {
    var note: String = ""
    var imageLocalPath: String?
    var isMilestone = false

    var hasImage: Bool {
        !(imageLocalPath?.trimmed.isEmpty ?? true)
    }

    var hasText: Bool {
        !note.trimmed.isEmpty
    }

    var hasAnyUserIntent: Bool {
        hasImage || hasText || isMilestone
    }

    var canSave: Bool {
        hasImage || hasText
    }

    mutating func reset() {
        note = ""
        imageLocalPath = nil
        isMilestone = false
    }
}

enum TreasureDataState: Equatable {
    case loading
    case empty
    case lowContent
    case ready
    case error
}

enum TreasureScrollIntentState: Equatable {
    case idle
    case readingDown
    case reversingUp
    case fastScrolling
    case monthScrubbing
}

enum TreasureFilterBarVisibilityState: Equatable {
    case inlineVisible
    case hiddenByScroll
    case pinnedVisible
}

enum TreasureMonthScrubberState: Equatable {
    case hidden
    case appearing
    case visible
    case dragging
    case fading
    case onboardingNudge
}

enum TreasureComposeState: Equatable {
    case closed
    case opening
    case editingEmpty
    case editingTextOnly
    case editingPhotoOnly
    case editingPhotoAndText
    case editingMilestone
    case confirmingDiscard
    case saving
    case failed

    var isPresented: Bool {
        self != .closed
    }
}

enum TreasureWeeklyLetterViewState: Equatable {
    case collapsed
    case expandedBottomSheet
}

struct TreasureViewState: Equatable {
    var currentFilter: TreasureFilter = .allMemories
    var dataState: TreasureDataState = .loading
    var scrollIntentState: TreasureScrollIntentState = .idle
    var filterBarVisibility: TreasureFilterBarVisibilityState = .inlineVisible
    var monthScrubberState: TreasureMonthScrubberState = .hidden
    var composeState: TreasureComposeState = .closed
    var weeklyLetterViewState: TreasureWeeklyLetterViewState = .collapsed
    var timelineItems: [TreasureTimelineItem] = []
    var monthAnchors: [TreasureMonthAnchor] = []
    var composeDraft = TreasureComposeDraft()
    var selectedWeeklyLetter: TreasureTimelineItem?
    var activeMonthAnchor: TreasureMonthAnchor?
    var undoToast: UndoToastState?
    var scrollTargetID: UUID?
    var errorMessage: String?
    var composeErrorMessage: String?
    var hasLoadedInitialData = false

    var hasVisibleContent: Bool {
        !timelineItems.isEmpty
    }
}

enum TreasureAction {
    case onAppear
    case selectFilter(TreasureFilter)
    case didScroll(offset: CGFloat, timestamp: TimeInterval)
    case tapAddToday
    case dismissCompose
    case confirmDiscard
    case cancelDiscard
    case updateNote(String)
    case toggleMilestone
    case setImagePath(String?)
    case removeImage
    case saveCompose
    case retrySaveCompose
    case dismissComposeError
    case undoLastEntry
    case dismissUndo
    case tapWeeklyLetter(UUID)
    case dismissWeeklyLetter
    case beginMonthScrubbing(height: CGFloat, locationY: CGFloat)
    case updateMonthScrubbing(height: CGFloat, locationY: CGFloat)
    case endMonthScrubbing
}
