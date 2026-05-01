import Foundation
import SwiftData

enum SproutSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [
        BabyProfile.self,
        RecordItem.self,
        MemoryEntry.self,
        WeeklyLetter.self,
    ]

    @Model
    final class BabyProfile {
        var name: String
        var birthDate: Date
        var gender: Gender?
        var createdAt: Date
        var avatarPath: String?
        var isActive: Bool
        var hasCompletedOnboarding: Bool

        enum Gender: String, Codable {
            case male
            case female
        }

        init(
            name: String,
            birthDate: Date,
            gender: Gender?,
            createdAt: Date,
            avatarPath: String?,
            isActive: Bool,
            hasCompletedOnboarding: Bool
        ) {
            self.name = name
            self.birthDate = birthDate
            self.gender = gender
            self.createdAt = createdAt
            self.avatarPath = avatarPath
            self.isActive = isActive
            self.hasCompletedOnboarding = hasCompletedOnboarding
        }
    }

    @Model
    final class RecordItem {
        @Attribute(.unique) var id: UUID
        var timestamp: Date
        var type: String
        var value: Double?
        var leftNursingSeconds: Int
        var rightNursingSeconds: Int
        var subType: String?
        var imageURL: String?
        var aiSummary: String?
        var tags: [String]?
        var note: String?

        init(
            id: UUID,
            timestamp: Date,
            type: String,
            value: Double?,
            leftNursingSeconds: Int,
            rightNursingSeconds: Int,
            subType: String?,
            imageURL: String?,
            aiSummary: String?,
            tags: [String]?,
            note: String?
        ) {
            self.id = id
            self.timestamp = timestamp
            self.type = type
            self.value = value
            self.leftNursingSeconds = leftNursingSeconds
            self.rightNursingSeconds = rightNursingSeconds
            self.subType = subType
            self.imageURL = imageURL
            self.aiSummary = aiSummary
            self.tags = tags
            self.note = note
        }
    }

    @Model
    final class MemoryEntry {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        var ageInDays: Int?
        var imageLocalPath: String?
        var note: String?
        var isMilestone: Bool

        init(
            id: UUID,
            createdAt: Date,
            ageInDays: Int?,
            imageLocalPath: String?,
            note: String?,
            isMilestone: Bool
        ) {
            self.id = id
            self.createdAt = createdAt
            self.ageInDays = ageInDays
            self.imageLocalPath = imageLocalPath
            self.note = note
            self.isMilestone = isMilestone
        }
    }

    @Model
    final class WeeklyLetter {
        @Attribute(.unique) var id: UUID
        var weekStart: Date
        var weekEnd: Date
        var density: WeeklyLetterDensity
        var collapsedText: String
        var expandedText: String
        var generatedAt: Date

        init(
            id: UUID,
            weekStart: Date,
            weekEnd: Date,
            density: WeeklyLetterDensity,
            collapsedText: String,
            expandedText: String,
            generatedAt: Date
        ) {
            self.id = id
            self.weekStart = weekStart
            self.weekEnd = weekEnd
            self.density = density
            self.collapsedText = collapsedText
            self.expandedText = expandedText
            self.generatedAt = generatedAt
        }
    }
}

enum SproutSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            RecordItem.self,
            MemoryEntry.self,
            WeeklyLetter.self,
            BabyProfile.self,
            SyncDeletionTombstone.self,
        ]
    }

    @Model
    final class BabyProfile {
        @Attribute(.unique) var id: UUID
        var name: String
        var birthDate: Date
        var gender: Gender?
        var createdAt: Date
        var avatarPath: String?
        var remoteAvatarPath: String?
        var remoteVersion: Int64?
        var syncStateRaw: String
        var isActive: Bool
        var hasCompletedOnboarding: Bool

        enum Gender: String, Codable {
            case male
            case female
        }

        init(
            id: UUID = UUID(),
            name: String,
            birthDate: Date,
            gender: Gender? = nil,
            createdAt: Date,
            avatarPath: String? = nil,
            remoteAvatarPath: String? = nil,
            remoteVersion: Int64? = nil,
            syncStateRaw: String = SyncState.pendingUpsert.rawValue,
            isActive: Bool = true,
            hasCompletedOnboarding: Bool = false
        ) {
            self.id = id
            self.name = name
            self.birthDate = birthDate
            self.gender = gender
            self.createdAt = createdAt
            self.avatarPath = avatarPath
            self.remoteAvatarPath = remoteAvatarPath
            self.remoteVersion = remoteVersion
            self.syncStateRaw = syncStateRaw
            self.isActive = isActive
            self.hasCompletedOnboarding = hasCompletedOnboarding
        }
    }

    @Model
    final class RecordItem {
        @Attribute(.unique) var id: UUID
        var babyID: UUID
        var timestamp: Date
        var type: String
        var value: Double?
        var leftNursingSeconds: Int
        var rightNursingSeconds: Int
        var subType: String?
        var imageURL: String?
        var remoteImagePath: String?
        var remoteVersion: Int64?
        var syncStateRaw: String
        var aiSummary: String?
        var tags: [String]?
        var note: String?

        init(
            id: UUID = UUID(),
            babyID: UUID = UUID(),
            timestamp: Date,
            type: String,
            value: Double? = nil,
            leftNursingSeconds: Int = 0,
            rightNursingSeconds: Int = 0,
            subType: String? = nil,
            imageURL: String? = nil,
            remoteImagePath: String? = nil,
            remoteVersion: Int64? = nil,
            syncStateRaw: String = SyncState.pendingUpsert.rawValue,
            aiSummary: String? = nil,
            tags: [String]? = nil,
            note: String? = nil
        ) {
            self.id = id
            self.babyID = babyID
            self.timestamp = timestamp
            self.type = type
            self.value = value
            self.leftNursingSeconds = leftNursingSeconds
            self.rightNursingSeconds = rightNursingSeconds
            self.subType = subType
            self.imageURL = imageURL
            self.remoteImagePath = remoteImagePath
            self.remoteVersion = remoteVersion
            self.syncStateRaw = syncStateRaw
            self.aiSummary = aiSummary
            self.tags = tags
            self.note = note
        }
    }

    @Model
    final class MemoryEntry {
        @Attribute(.unique) var id: UUID
        var babyID: UUID
        var createdAt: Date
        var ageInDays: Int?
        var imageLocalPath: String?
        var remoteImagePathsPayload: String?
        var remoteVersion: Int64?
        var syncStateRaw: String
        var note: String?
        var isMilestone: Bool

        init(
            id: UUID = UUID(),
            babyID: UUID = UUID(),
            createdAt: Date,
            ageInDays: Int?,
            imageLocalPath: String? = nil,
            remoteImagePathsPayload: String? = nil,
            remoteVersion: Int64? = nil,
            syncStateRaw: String = SyncState.pendingUpsert.rawValue,
            note: String? = nil,
            isMilestone: Bool = false
        ) {
            self.id = id
            self.babyID = babyID
            self.createdAt = createdAt
            self.ageInDays = ageInDays
            self.imageLocalPath = imageLocalPath
            self.remoteImagePathsPayload = remoteImagePathsPayload
            self.remoteVersion = remoteVersion
            self.syncStateRaw = syncStateRaw
            self.note = note
            self.isMilestone = isMilestone
        }
    }

    @Model
    final class WeeklyLetter {
        @Attribute(.unique) var id: UUID
        var weekStart: Date
        var weekEnd: Date
        var density: WeeklyLetterDensity
        var collapsedText: String
        var expandedText: String
        var generatedAt: Date

        init(
            id: UUID = UUID(),
            weekStart: Date,
            weekEnd: Date,
            density: WeeklyLetterDensity,
            collapsedText: String,
            expandedText: String,
            generatedAt: Date
        ) {
            self.id = id
            self.weekStart = weekStart
            self.weekEnd = weekEnd
            self.density = density
            self.collapsedText = collapsedText
            self.expandedText = expandedText
            self.generatedAt = generatedAt
        }
    }

    @Model
    final class SyncDeletionTombstone {
        @Attribute(.unique) var id: UUID
        var entityTypeRaw: String
        var entityID: UUID
        var remoteVersion: Int64?
        var readyAfter: Date
        var storagePathsPayload: String?

        init(
            id: UUID = UUID(),
            entityType: SyncDeletionEntityType,
            entityID: UUID,
            remoteVersion: Int64?,
            readyAfter: Date,
            storagePathsPayload: String? = nil
        ) {
            self.id = id
            entityTypeRaw = entityType.rawValue
            self.entityID = entityID
            self.remoteVersion = remoteVersion
            self.readyAfter = readyAfter
            self.storagePathsPayload = storagePathsPayload
        }
    }
}

enum SproutSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            RecordItem.self,
            MemoryEntry.self,
            WeeklyLetter.self,
            BabyProfile.self,
            SyncDeletionTombstone.self,
            GrowthMilestoneEntry.self,
        ]
    }

    @Model
    final class BabyProfile {
        @Attribute(.unique) var id: UUID
        var name: String
        var birthDate: Date
        var gender: Gender?
        var createdAt: Date
        var avatarPath: String?
        var remoteAvatarPath: String?
        var remoteVersion: Int64?
        var syncStateRaw: String
        var isActive: Bool
        var hasCompletedOnboarding: Bool

        enum Gender: String, Codable {
            case male
            case female
        }

        init(
            id: UUID = UUID(),
            name: String,
            birthDate: Date,
            gender: Gender? = nil,
            createdAt: Date,
            avatarPath: String? = nil,
            remoteAvatarPath: String? = nil,
            remoteVersion: Int64? = nil,
            syncStateRaw: String = SyncState.pendingUpsert.rawValue,
            isActive: Bool = true,
            hasCompletedOnboarding: Bool = false
        ) {
            self.id = id
            self.name = name
            self.birthDate = birthDate
            self.gender = gender
            self.createdAt = createdAt
            self.avatarPath = avatarPath
            self.remoteAvatarPath = remoteAvatarPath
            self.remoteVersion = remoteVersion
            self.syncStateRaw = syncStateRaw
            self.isActive = isActive
            self.hasCompletedOnboarding = hasCompletedOnboarding
        }
    }

    @Model
    final class RecordItem {
        @Attribute(.unique) var id: UUID
        var babyID: UUID
        var timestamp: Date
        var type: String
        var value: Double?
        var leftNursingSeconds: Int
        var rightNursingSeconds: Int
        var subType: String?
        var imageURL: String?
        var remoteImagePath: String?
        var remoteVersion: Int64?
        var syncStateRaw: String
        var aiSummary: String?
        var tags: [String]?
        var note: String?

        init(
            id: UUID = UUID(),
            babyID: UUID = UUID(),
            timestamp: Date,
            type: String,
            value: Double? = nil,
            leftNursingSeconds: Int = 0,
            rightNursingSeconds: Int = 0,
            subType: String? = nil,
            imageURL: String? = nil,
            remoteImagePath: String? = nil,
            remoteVersion: Int64? = nil,
            syncStateRaw: String = SyncState.pendingUpsert.rawValue,
            aiSummary: String? = nil,
            tags: [String]? = nil,
            note: String? = nil
        ) {
            self.id = id
            self.babyID = babyID
            self.timestamp = timestamp
            self.type = type
            self.value = value
            self.leftNursingSeconds = leftNursingSeconds
            self.rightNursingSeconds = rightNursingSeconds
            self.subType = subType
            self.imageURL = imageURL
            self.remoteImagePath = remoteImagePath
            self.remoteVersion = remoteVersion
            self.syncStateRaw = syncStateRaw
            self.aiSummary = aiSummary
            self.tags = tags
            self.note = note
        }
    }

    @Model
    final class MemoryEntry {
        @Attribute(.unique) var id: UUID
        var babyID: UUID
        var createdAt: Date
        var ageInDays: Int?
        var imageLocalPath: String?
        var remoteImagePathsPayload: String?
        var remoteVersion: Int64?
        var syncStateRaw: String
        var note: String?
        var isMilestone: Bool

        init(
            id: UUID = UUID(),
            babyID: UUID = UUID(),
            createdAt: Date,
            ageInDays: Int?,
            imageLocalPath: String? = nil,
            remoteImagePathsPayload: String? = nil,
            remoteVersion: Int64? = nil,
            syncStateRaw: String = SyncState.pendingUpsert.rawValue,
            note: String? = nil,
            isMilestone: Bool = false
        ) {
            self.id = id
            self.babyID = babyID
            self.createdAt = createdAt
            self.ageInDays = ageInDays
            self.imageLocalPath = imageLocalPath
            self.remoteImagePathsPayload = remoteImagePathsPayload
            self.remoteVersion = remoteVersion
            self.syncStateRaw = syncStateRaw
            self.note = note
            self.isMilestone = isMilestone
        }
    }

    @Model
    final class WeeklyLetter {
        @Attribute(.unique) var id: UUID
        var weekStart: Date
        var weekEnd: Date
        var density: WeeklyLetterDensity
        var collapsedText: String
        var expandedText: String
        var generatedAt: Date

        init(
            id: UUID = UUID(),
            weekStart: Date,
            weekEnd: Date,
            density: WeeklyLetterDensity,
            collapsedText: String,
            expandedText: String,
            generatedAt: Date
        ) {
            self.id = id
            self.weekStart = weekStart
            self.weekEnd = weekEnd
            self.density = density
            self.collapsedText = collapsedText
            self.expandedText = expandedText
            self.generatedAt = generatedAt
        }
    }

    @Model
    final class SyncDeletionTombstone {
        @Attribute(.unique) var id: UUID
        var entityTypeRaw: String
        var entityID: UUID
        var remoteVersion: Int64?
        var readyAfter: Date
        var storagePathsPayload: String?

        init(
            id: UUID = UUID(),
            entityType: SyncDeletionEntityType,
            entityID: UUID,
            remoteVersion: Int64?,
            readyAfter: Date,
            storagePathsPayload: String? = nil
        ) {
            self.id = id
            entityTypeRaw = entityType.rawValue
            self.entityID = entityID
            self.remoteVersion = remoteVersion
            self.readyAfter = readyAfter
            self.storagePathsPayload = storagePathsPayload
        }
    }

    @Model
    final class GrowthMilestoneEntry {
        @Attribute(.unique) var id: UUID
        var babyID: UUID
        var templateKey: String?
        var title: String
        var category: String
        var occurredAt: Date
        var note: String?
        var imageLocalPath: String?
        var remoteImagePath: String?
        var remoteVersion: Int64?
        var syncStateRaw: String
        var isCustom: Bool
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            babyID: UUID = UUID(),
            templateKey: String? = nil,
            title: String,
            category: String,
            occurredAt: Date,
            note: String? = nil,
            imageLocalPath: String? = nil,
            remoteImagePath: String? = nil,
            remoteVersion: Int64? = nil,
            syncStateRaw: String = SyncState.pendingUpsert.rawValue,
            isCustom: Bool = false,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.babyID = babyID
            self.templateKey = templateKey
            self.title = title
            self.category = category
            self.occurredAt = occurredAt
            self.note = note
            self.imageLocalPath = imageLocalPath
            self.remoteImagePath = remoteImagePath
            self.remoteVersion = remoteVersion
            self.syncStateRaw = syncStateRaw
            self.isCustom = isCustom
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}

enum SproutSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            RecordItem.self,
            MemoryEntry.self,
            WeeklyLetter.self,
            BabyProfile.self,
            SyncDeletionTombstone.self,
            GrowthMilestoneEntry.self,
            FamilyGroup.self,
        ]
    }
}

enum SproutMigrationPlan: SchemaMigrationPlan {
    private static let emptyUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    static var schemas: [any VersionedSchema.Type] {
        [
            SproutSchemaV1.self,
            SproutSchemaV2.self,
            SproutSchemaV3.self,
            SproutSchemaV4.self,
        ]
    }

    static var stages: [MigrationStage] {
        [
            migrateV1toV2,
            migrateV2toV3,
            migrateV3toV4,
        ]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SproutSchemaV1.self,
        toVersion: SproutSchemaV2.self,
        willMigrate: { _ in
            // v1 has no sync metadata. Backfill is done after mapping to v2.
        },
        didMigrate: { context in
            try normalizeMigratedRows(in: context)
        }
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SproutSchemaV2.self,
        toVersion: SproutSchemaV3.self
    )

    static let migrateV3toV4 = MigrationStage.custom(
        fromVersion: SproutSchemaV3.self,
        toVersion: SproutSchemaV4.self,
        willMigrate: { _ in
            // Optional authorship metadata is backfilled after mapping to v4.
        },
        didMigrate: { context in
            try normalizeV4Rows(in: context)
        }
    )

    private static func normalizeMigratedRows(in context: ModelContext) throws {
        var babies = try context.fetch(
            FetchDescriptor<SproutSchemaV2.BabyProfile>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
        )
        var hasChanges = false

        if babies.isEmpty {
            let defaultBaby = SproutSchemaV2.BabyProfile(
                name: BabyProfile.defaultName,
                birthDate: .now,
                createdAt: .now
            )
            context.insert(defaultBaby)
            babies = [defaultBaby]
            hasChanges = true
        }

        var usedIDs = Set<UUID>()
        for baby in babies {
            var candidateID = baby.id
            if candidateID == emptyUUID || usedIDs.contains(candidateID) {
                candidateID = UUID()
                baby.id = candidateID
                hasChanges = true
            }
            usedIDs.insert(candidateID)
        }

        guard let canonicalBaby = babies.first(where: \.isActive) ?? babies.first else {
            if hasChanges {
                try context.save()
            }
            return
        }

        let canonicalBabyID = canonicalBaby.id
        for baby in babies {
            let shouldBeActive = baby.id == canonicalBabyID
            if baby.isActive != shouldBeActive {
                baby.isActive = shouldBeActive
                hasChanges = true
            }
            if baby.remoteVersion != nil {
                baby.remoteVersion = nil
                hasChanges = true
            }
            if baby.syncStateRaw != SyncState.pendingUpsert.rawValue {
                baby.syncStateRaw = SyncState.pendingUpsert.rawValue
                hasChanges = true
            }
        }

        let records = try context.fetch(FetchDescriptor<SproutSchemaV2.RecordItem>())
        for record in records {
            if record.babyID != canonicalBabyID {
                record.babyID = canonicalBabyID
                hasChanges = true
            }
            if record.remoteVersion != nil {
                record.remoteVersion = nil
                hasChanges = true
            }
            if record.syncStateRaw != SyncState.pendingUpsert.rawValue {
                record.syncStateRaw = SyncState.pendingUpsert.rawValue
                hasChanges = true
            }
        }

        let memories = try context.fetch(FetchDescriptor<SproutSchemaV2.MemoryEntry>())
        for memory in memories {
            if memory.babyID != canonicalBabyID {
                memory.babyID = canonicalBabyID
                hasChanges = true
            }
            if memory.remoteVersion != nil {
                memory.remoteVersion = nil
                hasChanges = true
            }
            if memory.syncStateRaw != SyncState.pendingUpsert.rawValue {
                memory.syncStateRaw = SyncState.pendingUpsert.rawValue
                hasChanges = true
            }
        }

        if hasChanges {
            try context.save()
        }
    }

    private static func normalizeV4Rows(in context: ModelContext) throws {
        var hasChanges = false

        let records = try context.fetch(FetchDescriptor<RecordItem>())
        for record in records {
            if record.createdByUserID == nil, let updatedByUserID = record.updatedByUserID {
                record.createdByUserID = updatedByUserID
                hasChanges = true
            }
            if record.updatedByUserID == nil, let createdByUserID = record.createdByUserID {
                record.updatedByUserID = createdByUserID
                hasChanges = true
            }
        }

        let memories = try context.fetch(FetchDescriptor<MemoryEntry>())
        for memory in memories {
            if memory.createdByUserID == nil, let updatedByUserID = memory.updatedByUserID {
                memory.createdByUserID = updatedByUserID
                hasChanges = true
            }
            if memory.updatedByUserID == nil, let createdByUserID = memory.createdByUserID {
                memory.updatedByUserID = createdByUserID
                hasChanges = true
            }
        }

        let milestones = try context.fetch(FetchDescriptor<GrowthMilestoneEntry>())
        for milestone in milestones {
            if milestone.createdByUserID == nil, let updatedByUserID = milestone.updatedByUserID {
                milestone.createdByUserID = updatedByUserID
                hasChanges = true
            }
            if milestone.updatedByUserID == nil, let createdByUserID = milestone.createdByUserID {
                milestone.updatedByUserID = createdByUserID
                hasChanges = true
            }
        }

        if hasChanges {
            try context.save()
        }
    }
}

enum SproutSchemaRegistry {
    static var models: [any PersistentModel.Type] {
        SproutSchemaV4.models
    }

    static var schema: Schema {
        Schema(SproutSchemaV4.models, version: SproutSchemaV4.versionIdentifier)
    }
}

enum SproutContainerFactory {
    static func make(
        schema: Schema,
        modelConfiguration: ModelConfiguration
    ) throws -> ModelContainer {
        // We explicitly provide the migration plan so container creation is
        // migration-aware even while historical schemas are introduced gradually.
        try ModelContainer(
            for: schema,
            migrationPlan: SproutMigrationPlan.self,
            configurations: [modelConfiguration]
        )
    }
}
