import Foundation

struct FoodEditorDraftSnapshot: Equatable {
    var tags: [String]
    var note: String
    var imagePath: String?
    var timestamp: Date

    static func empty(at date: Date) -> Self {
        FoodEditorDraftSnapshot(tags: [], note: "", imagePath: nil, timestamp: date)
    }
}

struct FoodEditorSession {
    var baseline: FoodEditorDraftSnapshot
    var originalImagePath: String?

    static func create(at date: Date) -> Self {
        FoodEditorSession(
            baseline: .empty(at: date),
            originalImagePath: nil
        )
    }
}

struct SleepRecordEditDraft: Equatable {
    var originalStartTime: Date
    var originalEndTime: Date
    var startTime: Date
    var endTime: Date

    init(
        startTime: Date,
        endTime: Date,
        originalStartTime: Date? = nil,
        originalEndTime: Date? = nil
    ) {
        self.originalStartTime = originalStartTime ?? startTime
        self.originalEndTime = originalEndTime ?? endTime
        self.startTime = startTime
        self.endTime = endTime
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var hasChanges: Bool {
        startTime != originalStartTime || endTime != originalEndTime
    }

    var isValid: Bool {
        duration > 0
    }
}
