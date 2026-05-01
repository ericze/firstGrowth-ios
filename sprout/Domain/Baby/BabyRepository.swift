import Foundation
import OSLog
import SwiftData
import UIKit

@MainActor
final class BabyRepository {
    enum CreateBabyFailure: Error, Equatable {
        case entitlementBlocked
        case persistenceFailed
    }

    enum DeleteBabyFailure: Error, Equatable {
        case babyNotFound
        case onlyRemainingBaby
        case hasAssociatedData
        case persistenceFailed
    }

    struct DeleteBabyOutcome: Equatable {
        let activeBabyID: UUID
    }

    struct AccessibleBabyGroups {
        let owned: [BabyProfile]
        let shared: [BabyProfile]

        static let empty = AccessibleBabyGroups(owned: [], shared: [])
    }

    private let modelContext: ModelContext
    private let canCreateAdditionalBaby: (Int) -> Bool
    private let logger = Logger(subsystem: "sprout", category: "BabyRepository")
    weak var activeBabyState: ActiveBabyState?

    init(
        modelContext: ModelContext,
        activeBabyState: ActiveBabyState? = nil,
        canCreateAdditionalBaby: @escaping (Int) -> Bool = { _ in true }
    ) {
        self.modelContext = modelContext
        self.canCreateAdditionalBaby = canCreateAdditionalBaby
        self.activeBabyState = activeBabyState
    }

    var activeBaby: BabyProfile? {
        do {
            if let selectedID = activeBabyState?.headerConfig.babyID,
               let selectedBaby = try fetchBaby(id: selectedID) {
                return selectedBaby
            }
            return try fetchActiveBaby()
        } catch {
            recordFailure(operation: "Fetch active baby", error: error)
            return nil
        }
    }

    var activeBabyAccess: FamilyBabyAccess? {
        activeBabyState?.activeBabyAccess
    }

    @discardableResult
    func createDefaultIfNeeded() -> Bool {
        do {
            guard try fetchActiveBaby() == nil else { return true }
            let baby = BabyProfile(
                id: UUID(),
                syncStateRaw: SyncState.pendingUpsert.rawValue
            )
            modelContext.insert(baby)
            try modelContext.save()
            return true
        } catch {
            recordFailure(operation: "Create default baby", error: error)
            return false
        }
    }

    func fetchBabies() throws -> [BabyProfile] {
        let descriptor = FetchDescriptor<BabyProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAccessibleBabies(for currentUserID: UUID?) throws -> AccessibleBabyGroups {
        let babies = try fetchBabies()
        guard let currentUserID else {
            return AccessibleBabyGroups(owned: babies, shared: [])
        }

        let sharedIDs = try sharedBabyOwnerMap(for: currentUserID)
        return AccessibleBabyGroups(
            owned: babies.filter { sharedIDs[$0.id] == nil },
            shared: babies.filter { sharedIDs[$0.id] != nil }
        )
    }

    func createBaby(
        name: String,
        birthDate: Date,
        gender: BabyProfile.Gender? = nil,
        currentUserID: UUID? = nil
    ) -> BabyProfile? {
        switch createBabyResult(name: name, birthDate: birthDate, gender: gender, currentUserID: currentUserID) {
        case .success(let baby):
            return baby
        case .failure:
            return nil
        }
    }

    func createBabyResult(
        name: String,
        birthDate: Date,
        gender: BabyProfile.Gender? = nil,
        currentUserID: UUID? = nil
    ) -> Result<BabyProfile, CreateBabyFailure> {
        do {
            let babies = try fetchBabies()
            let entitlementBabyCount = try ownedBabyCount(in: babies, currentUserID: currentUserID)
            guard canCreateAdditionalBaby(entitlementBabyCount) else {
                recordFailure(operation: "Create baby", reason: "Multi-baby entitlement is not active")
                return .failure(.entitlementBlocked)
            }

            let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let baby = BabyProfile(
                id: UUID(),
                name: normalizedName.isEmpty ? BabyProfile.defaultName : normalizedName,
                birthDate: birthDate,
                gender: gender,
                createdAt: .now,
                syncStateRaw: SyncState.pendingUpsert.rawValue,
                isActive: true
            )

            for existingBaby in babies where existingBaby.isActive {
                existingBaby.isActive = false
                markPendingUpsert(existingBaby)
            }

            modelContext.insert(baby)
            try modelContext.save()
            activeBabyState?.updateFrom(baby)
            return .success(baby)
        } catch {
            recordFailure(operation: "Create baby", error: error)
            return .failure(.persistenceFailed)
        }
    }

    @discardableResult
    func activateBaby(id: UUID) -> Bool {
        do {
            let babies = try fetchBabies()
            guard let targetBaby = babies.first(where: { $0.id == id }) else {
                recordFailure(operation: "Activate baby", reason: "Baby not found")
                return false
            }

            for baby in babies {
                let shouldBeActive = baby.id == id
                guard baby.isActive != shouldBeActive else { continue }
                baby.isActive = shouldBeActive
                markPendingUpsert(baby)
            }

            try modelContext.save()
            activeBabyState?.updateFrom(
                targetBaby,
                access: FamilyBabyAccess(babyID: targetBaby.id, ownership: .owned)
            )
            return true
        } catch {
            recordFailure(operation: "Activate baby", error: error)
            return false
        }
    }

    @discardableResult
    func activateAccessibleBaby(id: UUID, currentUserID: UUID?) -> Bool {
        do {
            guard let targetBaby = try fetchBaby(id: id) else {
                recordFailure(operation: "Activate accessible baby", reason: "Baby not found")
                return false
            }
            if let currentUserID,
               let ownerID = try sharedBabyOwnerMap(for: currentUserID)[id] {
                activeBabyState?.updateFrom(
                    targetBaby,
                    access: FamilyBabyAccess(babyID: targetBaby.id, ownership: .shared(ownerUserID: ownerID))
                )
                return true
            }
            return activateBaby(id: id)
        } catch {
            recordFailure(operation: "Activate accessible baby", error: error)
            return false
        }
    }

    func access(for babyID: UUID, currentUserID: UUID?) throws -> FamilyBabyAccess? {
        guard try fetchBaby(id: babyID) != nil else { return nil }
        if let currentUserID,
           let ownerID = try sharedBabyOwnerMap(for: currentUserID)[babyID] {
            return FamilyBabyAccess(babyID: babyID, ownership: .shared(ownerUserID: ownerID))
        }
        return FamilyBabyAccess(babyID: babyID, ownership: .owned)
    }

    func deleteBabyResult(id: UUID) -> Result<DeleteBabyOutcome, DeleteBabyFailure> {
        do {
            let babies = try fetchBabies()
            guard let targetBaby = babies.first(where: { $0.id == id }) else {
                recordFailure(operation: "Delete baby", reason: "Baby not found")
                return .failure(.babyNotFound)
            }
            guard babies.count > 1 else {
                recordFailure(operation: "Delete baby", reason: "Cannot remove the last remaining baby")
                return .failure(.onlyRemainingBaby)
            }
            guard try !hasAssociatedData(for: id) else {
                recordFailure(operation: "Delete baby", reason: "Associated data still exists")
                return .failure(.hasAssociatedData)
            }

            let replacementBaby = babies.first(where: { $0.id != id })
            guard let replacementBaby else {
                recordFailure(operation: "Delete baby", reason: "No replacement baby available")
                return .failure(.onlyRemainingBaby)
            }
            let targetAvatarPath = targetBaby.avatarPath

            if targetBaby.isActive {
                for baby in babies where baby.id != id {
                    let shouldBeActive = baby.id == replacementBaby.id
                    guard baby.isActive != shouldBeActive else { continue }
                    baby.isActive = shouldBeActive
                    markPendingUpsert(baby)
                }
            }

            let tombstone = SyncDeletionTombstone(
                entityType: .babyProfile,
                entityID: targetBaby.id,
                remoteVersion: targetBaby.remoteVersion,
                readyAfter: .now
            )
            modelContext.insert(tombstone)
            modelContext.delete(targetBaby)
            try modelContext.save()

            if let targetAvatarPath {
                deleteAvatarFile(at: targetAvatarPath)
            }
            activeBabyState?.updateFrom(replacementBaby)
            return .success(DeleteBabyOutcome(activeBabyID: replacementBaby.id))
        } catch {
            recordFailure(operation: "Delete baby", error: error)
            return .failure(.persistenceFailed)
        }
    }

    @discardableResult
    func updateName(_ name: String) -> Bool {
        do {
            guard let baby = try fetchActiveBaby() else {
                recordFailure(operation: "Update baby name", reason: "No active baby found")
                return false
            }
            baby.name = name
            markPendingUpsert(baby)
            try modelContext.save()
            activeBabyState?.updateFrom(baby)
            return true
        } catch {
            recordFailure(operation: "Update baby name", error: error)
            return false
        }
    }

    @discardableResult
    func updateBirthDate(_ date: Date) -> Bool {
        do {
            guard let baby = try fetchActiveBaby() else {
                recordFailure(operation: "Update baby birth date", reason: "No active baby found")
                return false
            }
            baby.birthDate = date
            markPendingUpsert(baby)
            try modelContext.save()
            activeBabyState?.updateFrom(baby)
            return true
        } catch {
            recordFailure(operation: "Update baby birth date", error: error)
            return false
        }
    }

    @discardableResult
    func updateGender(_ gender: BabyProfile.Gender?) -> Bool {
        do {
            guard let baby = try fetchActiveBaby() else {
                recordFailure(operation: "Update baby gender", reason: "No active baby found")
                return false
            }
            baby.gender = gender
            markPendingUpsert(baby)
            try modelContext.save()
            activeBabyState?.updateFrom(baby)
            return true
        } catch {
            recordFailure(operation: "Update baby gender", error: error)
            return false
        }
    }

    @discardableResult
    func updateAvatar(_ image: UIImage?) -> Bool {
        do {
            guard let baby = try fetchActiveBaby() else {
                recordFailure(operation: "Update baby avatar", reason: "No active baby found")
                return false
            }

            let oldPath = baby.avatarPath

            if let image {
                let resized = Self.resizeImage(image, maxDimension: 512)
                guard let data = resized.jpegData(compressionQuality: 0.8) else {
                    recordFailure(operation: "Update baby avatar", reason: "JPEG encoding failed")
                    return false
                }

                try ensureAvatarDirectory()
                let fileName = "avatar-\(UUID().uuidString).jpg"
                let fileURL = avatarDirectoryURL.appendingPathComponent(fileName)
                try data.write(to: fileURL, options: .atomic)
                baby.avatarPath = fileURL.path
            } else {
                baby.avatarPath = nil
            }

            markPendingUpsert(baby)
            try modelContext.save()

            if let oldPath {
                deleteAvatarFile(at: oldPath)
            }

            activeBabyState?.updateFrom(baby)
            return true
        } catch {
            recordFailure(operation: "Update baby avatar", error: error)
            return false
        }
    }

    @discardableResult
    func markOnboardingCompleted() -> Bool {
        do {
            guard let baby = try fetchActiveBaby() else {
                recordFailure(operation: "Mark onboarding completed", reason: "No active baby found")
                return false
            }
            baby.hasCompletedOnboarding = true
            markPendingUpsert(baby)
            try modelContext.save()
            return true
        } catch {
            recordFailure(operation: "Mark onboarding completed", error: error)
            return false
        }
    }

    private func fetchActiveBaby() throws -> BabyProfile? {
        var descriptor = FetchDescriptor<BabyProfile>(
            predicate: #Predicate<BabyProfile> { $0.isActive == true }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchBaby(id: UUID) throws -> BabyProfile? {
        var descriptor = FetchDescriptor<BabyProfile>(
            predicate: #Predicate<BabyProfile> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func ownedBabyCount(in babies: [BabyProfile], currentUserID: UUID?) throws -> Int {
        guard let currentUserID else { return babies.count }
        let sharedIDs = try sharedBabyOwnerMap(for: currentUserID)
        return babies.filter { sharedIDs[$0.id] == nil }.count
    }

    private func sharedBabyOwnerMap(for currentUserID: UUID) throws -> [UUID: UUID] {
        let groups = try modelContext.fetch(FetchDescriptor<FamilyGroup>())
        var ownerByBabyID: [UUID: UUID] = [:]

        for group in groups where group.ownerUserID != currentUserID {
            let isActiveMember = group.memberPayloads.contains { snapshot in
                snapshot.userID == currentUserID && snapshot.removedAt == nil
            }
            guard isActiveMember else { continue }
            for babyID in group.sharedBabyIDs {
                ownerByBabyID[babyID] = group.ownerUserID
            }
        }

        return ownerByBabyID
    }

    private func recordFailure(operation: String, error: Error) {
        logger.error("\(operation, privacy: .public) failed: \(String(describing: error), privacy: .public)")
    }

    private func recordFailure(operation: String, reason: String) {
        logger.error("\(operation, privacy: .public) failed: \(reason, privacy: .public)")
    }

    private func markPendingUpsert(_ baby: BabyProfile) {
        if baby.syncState != .pendingUpsert {
            baby.syncState = .pendingUpsert
        }
    }

    private func hasAssociatedData(for babyID: UUID) throws -> Bool {
        var recordDescriptor = FetchDescriptor<RecordItem>(
            predicate: #Predicate<RecordItem> { $0.babyID == babyID }
        )
        recordDescriptor.fetchLimit = 1
        if try !modelContext.fetch(recordDescriptor).isEmpty {
            return true
        }

        var memoryDescriptor = FetchDescriptor<MemoryEntry>(
            predicate: #Predicate<MemoryEntry> { $0.babyID == babyID }
        )
        memoryDescriptor.fetchLimit = 1
        if try !modelContext.fetch(memoryDescriptor).isEmpty {
            return true
        }

        var milestoneDescriptor = FetchDescriptor<GrowthMilestoneEntry>(
            predicate: #Predicate<GrowthMilestoneEntry> { $0.babyID == babyID }
        )
        milestoneDescriptor.fetchLimit = 1
        return try !modelContext.fetch(milestoneDescriptor).isEmpty
    }

    private var avatarDirectoryURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return root.appendingPathComponent("BabyAvatars", isDirectory: true)
    }

    private func ensureAvatarDirectory() throws {
        try FileManager.default.createDirectory(
            at: avatarDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    private func deleteAvatarFile(at path: String) {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            if FileManager.default.fileExists(atPath: trimmed) {
                try FileManager.default.removeItem(atPath: trimmed)
            }
        } catch {
            logger.error("Failed deleting old avatar: \(String(describing: error), privacy: .public)")
        }
    }

    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
