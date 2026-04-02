import Foundation
import SwiftData

@Model
final class MemoryEntry {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var ageInDays: Int?
    var imageLocalPath: String?
    var note: String?
    var isMilestone: Bool

    var imageLocalPaths: [String] {
        get { TreasureImagePathCodec.decodeStorageValue(imageLocalPath) }
        set { imageLocalPath = TreasureImagePathCodec.encodeStorageValue(for: newValue) }
    }

    init(
        id: UUID = UUID(),
        createdAt: Date,
        ageInDays: Int?,
        imageLocalPaths: [String] = [],
        note: String? = nil,
        isMilestone: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.ageInDays = ageInDays
        self.imageLocalPath = TreasureImagePathCodec.encodeStorageValue(for: imageLocalPaths)
        self.note = note
        self.isMilestone = isMilestone
    }
}
