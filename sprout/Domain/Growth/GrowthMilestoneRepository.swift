import Foundation
import SwiftData

nonisolated final class GrowthMilestoneRepository {
    private let modelContext: ModelContext
    private let currentUserIDProvider: () -> UUID?
    private let accessProvider: (UUID) throws -> FamilyBabyAccess?

    @MainActor
    init(
        modelContext: ModelContext,
        currentUserIDProvider: @escaping () -> UUID? = { nil },
        accessProvider: @escaping (UUID) throws -> FamilyBabyAccess? = { _ in nil }
    ) {
        self.modelContext = modelContext
        self.currentUserIDProvider = currentUserIDProvider
        self.accessProvider = accessProvider
    }
}

enum GrowthMilestoneRepositoryError: Error, Equatable {
    case permissionDenied(UUID)
}

@MainActor
extension GrowthMilestoneRepository {
    func createMilestone(
        babyID: UUID,
        title: String,
        templateKey: String? = nil,
        category: String,
        occurredAt: Date,
        note: String? = nil,
        imageLocalPath: String? = nil,
        isCustom: Bool = false
    ) throws -> GrowthMilestoneEntry {
        let entry = GrowthMilestoneEntry(
            babyID: babyID,
            templateKey: templateKey,
            title: title,
            category: category,
            occurredAt: occurredAt,
            note: note,
            imageLocalPath: imageLocalPath,
            createdByUserID: currentUserIDProvider(),
            updatedByUserID: currentUserIDProvider(),
            isCustom: isCustom
        )
        modelContext.insert(entry)
        try modelContext.save()
        return entry
    }

    func fetchMilestones(for babyID: UUID) throws -> [GrowthMilestoneEntry] {
        let descriptor = FetchDescriptor<GrowthMilestoneEntry>(
            predicate: #Predicate<GrowthMilestoneEntry> { item in
                item.babyID == babyID
            },
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchMilestone(id: UUID) throws -> GrowthMilestoneEntry? {
        var descriptor = FetchDescriptor<GrowthMilestoneEntry>(
            predicate: #Predicate<GrowthMilestoneEntry> { item in
                item.id == id
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func updateMilestone(
        _ entry: GrowthMilestoneEntry,
        title: String? = nil,
        note: String? = nil,
        occurredAt: Date? = nil
    ) throws {
        try enforceCanEdit(entry)
        if let title { entry.title = title }
        if let note { entry.note = note }
        if let occurredAt { entry.occurredAt = occurredAt }
        entry.syncStateRaw = SyncState.pendingUpsert.rawValue
        if let currentUserID = currentUserIDProvider() {
            entry.updatedByUserID = currentUserID
        }
        entry.updatedAt = Date()
        try modelContext.save()
    }

    func deleteMilestone(id: UUID) throws {
        var descriptor = FetchDescriptor<GrowthMilestoneEntry>(
            predicate: #Predicate<GrowthMilestoneEntry> { item in
                item.id == id
            }
        )
        descriptor.fetchLimit = 1

        guard let entry = try modelContext.fetch(descriptor).first else { return }
        try enforceCanEdit(entry)
        modelContext.delete(entry)
        try modelContext.save()
    }

    private func enforceCanEdit(_ entry: GrowthMilestoneEntry) throws {
        let access = try accessProvider(entry.babyID) ?? FamilyBabyAccess(babyID: entry.babyID, ownership: .owned)
        guard FamilyPermission.canEdit(
            authoredBy: entry.createdByUserID,
            currentUserID: currentUserIDProvider(),
            access: access
        ) else {
            throw GrowthMilestoneRepositoryError.permissionDenied(entry.id)
        }
    }
}
