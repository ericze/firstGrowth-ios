import Foundation
import SwiftData

enum FamilyInviteState: String, Codable, Equatable, Sendable {
    case active
    case expired
    case revoked
}

enum FamilyMemberRole: String, Codable, Equatable, Sendable {
    case owner
    case member
}

enum BabyOwnership: Equatable, Sendable {
    case owned
    case shared(ownerUserID: UUID)
}

struct FamilyBabyAccess: Equatable, Sendable, Identifiable {
    let babyID: UUID
    let ownership: BabyOwnership

    var id: UUID { babyID }
}

struct FamilyMemberSnapshot: Codable, Equatable, Sendable {
    let userID: UUID
    let role: FamilyMemberRole
    let joinedAt: Date
    let removedAt: Date?
}

@Model
final class FamilyGroup {
    @Attribute(.unique) var id: UUID
    var ownerUserID: UUID
    var inviteCode: String?
    var inviteExpiresAt: Date?
    var inviteStateRaw: String
    var sharedBabyIDs: [UUID]
    var memberPayloads: [FamilyMemberSnapshot]
    var remoteVersion: Int64?
    var syncStateRaw: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        ownerUserID: UUID,
        inviteCode: String? = nil,
        inviteExpiresAt: Date? = nil,
        inviteState: FamilyInviteState = .revoked,
        sharedBabyIDs: [UUID] = [],
        memberPayloads: [FamilyMemberSnapshot] = [],
        remoteVersion: Int64? = nil,
        syncStateRaw: String = SyncState.pendingUpsert.rawValue,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerUserID = ownerUserID
        self.inviteCode = inviteCode
        self.inviteExpiresAt = inviteExpiresAt
        self.inviteStateRaw = inviteState.rawValue
        self.sharedBabyIDs = sharedBabyIDs
        self.memberPayloads = memberPayloads
        self.remoteVersion = remoteVersion
        self.syncStateRaw = syncStateRaw
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension FamilyGroup {
    var inviteState: FamilyInviteState {
        get { FamilyInviteState(rawValue: inviteStateRaw) ?? .revoked }
        set { inviteStateRaw = newValue.rawValue }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .pendingUpsert }
        set { syncStateRaw = newValue.rawValue }
    }
}
