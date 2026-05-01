import Foundation
import OSLog
import SwiftData

@MainActor
final class FamilyGroupRepository {
    enum Failure: Error, Equatable {
        case familyGroupAlreadyExists
        case familyGroupNotFound
        case notOwner
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

        do {
            try modelContext.save()
            return familyGroup
        } catch {
            recordFailure(operation: "Rotate family invite code", error: error)
            throw Failure.persistenceFailed
        }
    }

    private func fetchFamilyGroups() throws -> [FamilyGroup] {
        let descriptor = FetchDescriptor<FamilyGroup>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func recordFailure(operation: String, error: Error) {
        logger.error("\(operation, privacy: .public) failed: \(String(describing: error), privacy: .public)")
    }

    private static func defaultInviteCode() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).uppercased()
    }
}
