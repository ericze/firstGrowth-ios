import Foundation
import SwiftData

@Model
final class MemoryEntry {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var ageInDays: Int?
    var imageLocalPaths: [String]
    var imageLocalPath: String?
    var note: String?
    var isMilestone: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date,
        ageInDays: Int?,
        imageLocalPaths: [String] = [],
        imageLocalPath: String? = nil,
        note: String? = nil,
        isMilestone: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.ageInDays = ageInDays
        self.imageLocalPaths = imageLocalPaths
        self.imageLocalPath = imageLocalPath
        self.note = note
        self.isMilestone = isMilestone
    }
}
