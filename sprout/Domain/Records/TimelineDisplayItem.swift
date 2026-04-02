import Foundation

struct TimelineDisplayItem: Identifiable, Equatable {
    let id: UUID
    let recordID: UUID
    let timestamp: Date
    let cardStyle: TimelineCardStyle
    let leadingIcon: RecordIcon
    let title: String
    let subtitle: String?
    let imagePath: String?
    let type: RecordType
}
