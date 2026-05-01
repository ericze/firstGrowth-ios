import Foundation
import OSLog
import SwiftData

@MainActor
final class FamilyGroupRepository {
    enum Failure: Error, Equatable {
        case familyGroupAlreadyExists
        case familyGroupNotFound
        case invalidInviteCode
        case inviteExpired
        case inviteRevoked
        case notOwner
        case babyNotFound
        case memberNotFound
        case cannotRemoveOwner
        case persistenceFailed
    }

    private let modelContext: ModelContext
    private let nowProvider: () -> Date
    private let inviteCodeGenerator: () -> String
    private let logger = Logger(subsystem: "sprout", category: "FamilyGroupRepository")

    init(
        modelContext: ModelContext,
        nowProvider: @escaping () -> Date = Date.init,
        inviteCodeGenerator: @escaping () -> String = FamilyGroupRepository.defaultInviteCode
    ) {
        self.modelContext = modelContext
        self.nowProvider = nowProvider
        self.inviteCodeGenerator = inviteCodeGenerator
    }

    func loadCurrentFamilyGroup(for currentUserID: UUID?) throws -> FamilyGroup? {
        guard let currentUserID else { return nil }
        let groups = try fetchFamilyGroups()
        return groups.first(where: { group in
            group.ownerUserID == currentUserID || group.memberPayloads.contains(where: { snapshot in
                snapshot.userID == currentUserID && snapshot.removedAt == nil
            })
        })
    }

    func createFamilyGroup(for currentUserID: UUID) throws -> FamilyGroup {
        if try loadCurrentFamilyGroup(for: currentUserID) != nil {
            throw Failure.familyGroupAlreadyExists
        }

        let now = nowProvider()
        let familyGroup = FamilyGroup(
            ownerUserID: currentUserID,
            inviteCode: inviteCodeGenerator(),
            inviteExpiresAt: nil,
            inviteState: .active,
            sharedBabyIDs: [],
            memberPayloads: [
                FamilyMemberSnapshot(
                    userID: currentUserID,
                    role: .owner,
                    joinedAt: now,
                    removedAt: nil
                )
            ],
            createdAt: now,
            updatedAt: now
        )

        modelContext.insert(familyGroup)
        do {
            try modelContext.save()
            return familyGroup
        } catch {
            recordFailure(operation: "Create family group", error: error)
            throw Failure.persistenceFailed
        }
    }

    func joinFamilyGroup(withInviteCode inviteCode: String, for currentUserID: UUID) throws -> FamilyGroup {
        if try loadCurrentFamilyGroup(for: currentUserID) != nil {
            throw Failure.familyGroupAlreadyExists
        }

        let normalizedInviteCode = normalizeInviteCode(inviteCode)
        guard !normalizedInviteCode.isEmpty else {
            throw Failure.invalidInviteCode
        }

        guard let familyGroup = try fetchFamilyGroups().first(where: { $0.inviteCode == normalizedInviteCode }) else {
            throw Failure.invalidInviteCode
        }

        try validateJoinable(familyGroup)

        let now = nowProvider()
        familyGroup.memberPayloads.append(
            FamilyMemberSnapshot(
                userID: currentUserID,
                role: .member,
                joinedAt: now,
                removedAt: nil
            )
        )
        familyGroup.updatedAt = now
        familyGroup.syncState = .pendingUpsert

        do {
            try modelContext.save()
            return familyGroup
        } catch {
            recordFailure(operation: "Join family group", error: error)
            throw Failure.persistenceFailed
        }
    }

    func rotateInviteCode(for currentUserID: UUID) throws -> FamilyGroup {
        guard let familyGroup = try loadCurrentFamilyGroup(for: currentUserID) else {
            throw Failure.familyGroupNotFound
        }
        guard familyGroup.ownerUserID == currentUserID else {
            throw Failure.notOwner
        }

        familyGroup.inviteCode = inviteCodeGenerator()
        familyGroup.inviteExpiresAt = nil
        familyGroup.inviteState = .active
        familyGroup.updatedAt = nowProvider()
        familyGroup.syncState = .pendingUpsert

        do {
            try modelContext.save()
            return familyGroup
        } catch {
            recordFailure(operation: "Rotate family invite code", error: error)
            throw Failure.persistenceFailed
        }
    }

    func setBabyShared(_ babyID: UUID, shared: Bool, for currentUserID: UUID) throws -> FamilyGroup {
        guard let familyGroup = try loadCurrentFamilyGroup(for: currentUserID) else {
            throw Failure.familyGroupNotFound
        }
        guard familyGroup.ownerUserID == currentUserID else {
            throw Failure.notOwner
        }
        guard try fetchBaby(id: babyID) != nil else {
            throw Failure.babyNotFound
        }

        if shared {
            if !familyGroup.sharedBabyIDs.contains(babyID) {
                familyGroup.sharedBabyIDs.append(babyID)
            }
        } else {
            familyGroup.sharedBabyIDs.removeAll { $0 == babyID }
        }

        familyGroup.updatedAt = nowProvider()
        familyGroup.syncState = .pendingUpsert

        do {
            try modelContext.save()
            return familyGroup
        } catch {
            recordFailure(operation: "Update shared baby", error: error)
            throw Failure.persistenceFailed
        }
    }

    func removeMember(userID: UUID, for currentUserID: UUID) throws -> FamilyGroup {
        guard let familyGroup = try loadCurrentFamilyGroup(for: currentUserID) else {
            throw Failure.familyGroupNotFound
        }
        guard familyGroup.ownerUserID == currentUserID else {
            throw Failure.notOwner
        }
        guard userID != familyGroup.ownerUserID else {
            throw Failure.cannotRemoveOwner
        }

        guard let memberIndex = familyGroup.memberPayloads.firstIndex(where: { snapshot in
            snapshot.userID == userID && snapshot.removedAt == nil
        }) else {
            throw Failure.memberNotFound
        }

        let now = nowProvider()
        var snapshot = familyGroup.memberPayloads[memberIndex]
        snapshot = FamilyMemberSnapshot(
            userID: snapshot.userID,
            role: snapshot.role,
            joinedAt: snapshot.joinedAt,
            removedAt: now
        )
        familyGroup.memberPayloads[memberIndex] = snapshot
        familyGroup.updatedAt = now
        familyGroup.syncState = .pendingUpsert

        do {
            try modelContext.save()
            return familyGroup
        } catch {
            recordFailure(operation: "Remove family member", error: error)
            throw Failure.persistenceFailed
        }
    }

    private func fetchFamilyGroups() throws -> [FamilyGroup] {
        let descriptor = FetchDescriptor<FamilyGroup>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchBaby(id: UUID) throws -> BabyProfile? {
        var descriptor = FetchDescriptor<BabyProfile>(
            predicate: #Predicate<BabyProfile> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func validateJoinable(_ familyGroup: FamilyGroup) throws {
        switch familyGroup.inviteState {
        case .revoked:
            throw Failure.inviteRevoked
        case .expired:
            throw Failure.inviteExpired
        case .active:
            break
        }

        if let expiresAt = familyGroup.inviteExpiresAt,
           expiresAt <= nowProvider() {
            familyGroup.inviteState = .expired
            familyGroup.updatedAt = nowProvider()
            familyGroup.syncState = .pendingUpsert
            do {
                try modelContext.save()
            } catch {
                recordFailure(operation: "Expire family invite", error: error)
                throw Failure.persistenceFailed
            }
            throw Failure.inviteExpired
        }
    }

    private func normalizeInviteCode(_ inviteCode: String) -> String {
        inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func recordFailure(operation: String, error: Error) {
        logger.error("\(operation, privacy: .public) failed: \(String(describing: error), privacy: .public)")
    }

    nonisolated private static func defaultInviteCode() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).uppercased()
    }
}
