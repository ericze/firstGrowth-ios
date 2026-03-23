import Foundation

struct SleepSessionState: Codable, Equatable {
    let id: UUID
    let startedAt: Date
    let isActive: Bool
}
