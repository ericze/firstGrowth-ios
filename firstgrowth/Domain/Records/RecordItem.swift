import Foundation
import SwiftData

@Model
final class RecordItem {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var type: String
    var value: Double?
    var subType: String?
    var imageURL: String?
    var aiSummary: String?
    var tags: [String]?
    var note: String?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        type: String,
        value: Double? = nil,
        subType: String? = nil,
        imageURL: String? = nil,
        aiSummary: String? = nil,
        tags: [String]? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.value = value
        self.subType = subType
        self.imageURL = imageURL
        self.aiSummary = aiSummary
        self.tags = tags
        self.note = note
    }
}

extension RecordItem {
    var recordType: RecordType? {
        RecordType(rawValue: type)
    }

    var diaperType: DiaperSubtype? {
        guard let subType else { return nil }
        return DiaperSubtype(rawValue: subType)
    }
}
