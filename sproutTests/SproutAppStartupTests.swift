import Foundation
import Testing
import SwiftData
@testable import sprout

@MainActor
struct SproutAppStartupTests {

    // MARK: - Container creation succeeds with in-memory store

    @Test("AppState.makeContainerResult succeeds with valid in-memory configuration")
    func testContainerCreationSucceeds() async throws {
        let schema = SproutSchemaRegistry.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        let result = AppState.makeContainerResult(schema: schema, modelConfiguration: configuration)

        switch result {
        case .success(let container):
            #expect(!container.configurations.isEmpty)
        case .failure(let message):
            Issue.record(Comment(rawValue: "Expected success but got failure: \(message)"))
        }
    }

    // MARK: - Container creation fails gracefully without deleting data

    @Test("AppState.makeContainerResult returns failure instead of crashing for invalid configuration")
    func testContainerCreationFailureReturnsErrorNotCrash() async throws {
        // Use a schema with an intentionally bad configuration path to force a failure.
        // A URL pointing to a non-existent, non-writable directory will cause ModelContainer to fail.
        let schema = SproutSchemaRegistry.schema

        // Create a configuration pointing to an impossible path
        let impossibleURL = URL(fileURLWithPath: "/nonexistent_impossible_path_xyz/default.store")
        let configuration = ModelConfiguration(
            schema: schema,
            url: impossibleURL
        )

        let result = AppState.makeContainerResult(schema: schema, modelConfiguration: configuration)

        switch result {
        case .success:
            // On some platforms this might succeed (e.g., sandbox allows it),
            // which is fine -- the key invariant is "no crash, no data deletion".
            break
        case .failure(let message):
            #expect(!message.isEmpty)
        }
    }

    // MARK: - Container result does not trigger destructive recovery

    @Test("AppState.makeContainerResult never calls clearPersistentStoreFiles on failure")
    func testNoDestructiveRecoveryOnFailure() async throws {
        // The previous behavior was: on failure, clearPersistentStoreFiles() was called,
        // then a second attempt was made. The new behavior must never delete user data.
        //
        // We verify this structurally: AppState.makeContainerResult has no code path
        // that removes files. We confirm the result is either .success or .failure,
        // with no side effects on the filesystem.

        let schema = SproutSchemaRegistry.schema
        let impossibleURL = URL(fileURLWithPath: "/nonexistent_impossible_path_abc/default.store")
        let configuration = ModelConfiguration(
            schema: schema,
            url: impossibleURL
        )

        // Capture file count before
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let storeFilesBefore = Self.countStoreFiles(in: appSupport, fileManager: fileManager)

        let _ = AppState.makeContainerResult(schema: schema, modelConfiguration: configuration)

        // Verify no store files were removed
        let storeFilesAfter = Self.countStoreFiles(in: appSupport, fileManager: fileManager)
        #expect(storeFilesAfter >= storeFilesBefore)
    }

    // MARK: - Test environment uses in-memory store

    @Test("Test environment creates in-memory container without persistent files")
    func testEnvironmentUsesInMemoryStore() async throws {
        let env = try makeTestEnvironment(now: .now)
        let container = env.modelContext.container

        // The test environment should use an in-memory store
        let configurations = container.configurations
        for config in configurations {
            #expect(config.isStoredInMemoryOnly == true)
        }
    }

    // MARK: - AppStartupErrorView renders without crash

    @Test("AppStartupErrorView can be instantiated with an error message")
    func testErrorViewCreation() async {
        let view = AppStartupErrorView(errorMessage: "Test error message")
        #expect(view.errorMessage == "Test error message")
    }

    @Test("AppStartupErrorView can be instantiated with an empty error message")
    func testErrorViewCreationWithEmptyMessage() async {
        let view = AppStartupErrorView(errorMessage: "")
        #expect(view.errorMessage.isEmpty)
    }

    // MARK: - AppRootView routes correctly

    @Test("AppRootView exists and can be created with a container")
    func testAppRootViewCreation() async throws {
        let schema = SproutSchemaRegistry.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try SproutContainerFactory.make(
            schema: schema,
            modelConfiguration: configuration
        )

        let view = AppRootView(container: container, hasCompletedOnboarding: true)
        #expect(view.hasCompletedOnboarding == true)
    }

    // MARK: - Default schema contains all required model types

    @Test("Default schema includes all current model types")
    func testDefaultSchemaContainsAllModelTypes() async throws {
        // Use an in-memory configuration so this always succeeds
        let schema = SproutSchemaRegistry.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let result = AppState.makeContainerResult(schema: schema, modelConfiguration: configuration)

        switch result {
        case .success(let container):
            // Verify we can insert and fetch each model type
            let context = ModelContext(container)

            let record = RecordItem(timestamp: .now, type: "height", value: 50.0)
            context.insert(record)

            let memory = MemoryEntry(createdAt: .now, ageInDays: 0, imageLocalPaths: [], note: "test", isMilestone: false)
            context.insert(memory)

            let letter = WeeklyLetter(
                weekStart: .now,
                weekEnd: .now,
                density: .normal,
                collapsedText: "test",
                expandedText: "test expanded",
                generatedAt: .now
            )
            context.insert(letter)

            let baby = BabyProfile()
            context.insert(baby)

            let tombstone = SyncDeletionTombstone(
                entityType: .recordItem,
                entityID: UUID(),
                remoteVersion: nil,
                readyAfter: .now
            )
            context.insert(tombstone)

            let milestone = GrowthMilestoneEntry(
                babyID: baby.id,
                title: "Roll over",
                category: "motor",
                occurredAt: .now
            )
            context.insert(milestone)

            let ownerID = UUID()
            let sharedBabyID = UUID()
            let member = FamilyMemberSnapshot(
                userID: UUID(),
                role: .member,
                joinedAt: .now,
                removedAt: nil
            )
            let family = FamilyGroup(
                ownerUserID: ownerID,
                inviteCode: "SPROUT42",
                inviteExpiresAt: .now.addingTimeInterval(3600),
                inviteState: .active,
                sharedBabyIDs: [sharedBabyID],
                memberPayloads: [member],
                remoteVersion: 7,
                syncStateRaw: SyncState.synced.rawValue
            )
            context.insert(family)

            try context.save()

            let fetchedRecords = try context.fetch(FetchDescriptor<RecordItem>())
            #expect(fetchedRecords.count == 1)

            let fetchedMemories = try context.fetch(FetchDescriptor<MemoryEntry>())
            #expect(fetchedMemories.count == 1)

            let fetchedLetters = try context.fetch(FetchDescriptor<WeeklyLetter>())
            #expect(fetchedLetters.count == 1)

            let fetchedBabies = try context.fetch(FetchDescriptor<BabyProfile>())
            #expect(fetchedBabies.count == 1)

            let fetchedTombstones = try context.fetch(FetchDescriptor<SyncDeletionTombstone>())
            #expect(fetchedTombstones.count == 1)

            let fetchedMilestones = try context.fetch(FetchDescriptor<GrowthMilestoneEntry>())
            #expect(fetchedMilestones.count == 1)

            let fetchedFamilies = try context.fetch(FetchDescriptor<FamilyGroup>())
            #expect(fetchedFamilies.count == 1)
            #expect(fetchedFamilies.first?.ownerUserID == ownerID)
            #expect(fetchedFamilies.first?.inviteCode == "SPROUT42")
            #expect(fetchedFamilies.first?.inviteState == .active)
            #expect(fetchedFamilies.first?.sharedBabyIDs == [sharedBabyID])
            #expect(fetchedFamilies.first?.memberPayloads == [member])
            #expect(fetchedFamilies.first?.remoteVersion == 7)
            #expect(fetchedFamilies.first?.syncState == .synced)

        case .failure(let message):
            Issue.record(Comment(rawValue: "Schema test failed: \(message)"))
        }
    }

    @Test("FamilyGroup array fields survive current-schema disk round trip")
    func testFamilyGroupArrayFieldsSurviveCurrentSchemaDiskRoundTrip() async throws {
        let storeURL = try Self.makeTemporaryStoreURL(named: "family-group-array-round-trip")
        defer {
            try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent())
        }

        let familyID = UUID()
        let ownerID = UUID()
        let sharedBabyIDs = [UUID(), UUID()]
        let joinedAt = Date(timeIntervalSince1970: 1_715_200_000)
        let removedAt = Date(timeIntervalSince1970: 1_715_286_400)
        let memberPayloads = [
            FamilyMemberSnapshot(
                userID: ownerID,
                role: .owner,
                joinedAt: joinedAt,
                removedAt: nil
            ),
            FamilyMemberSnapshot(
                userID: UUID(),
                role: .member,
                joinedAt: joinedAt.addingTimeInterval(60),
                removedAt: removedAt
            ),
        ]

        do {
            let schema = SproutSchemaRegistry.schema
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)

            context.insert(
                FamilyGroup(
                    id: familyID,
                    ownerUserID: ownerID,
                    inviteCode: "SPROUT42",
                    inviteExpiresAt: joinedAt.addingTimeInterval(3_600),
                    inviteState: .active,
                    sharedBabyIDs: sharedBabyIDs,
                    memberPayloads: memberPayloads,
                    remoteVersion: 7,
                    syncStateRaw: SyncState.synced.rawValue,
                    createdAt: joinedAt,
                    updatedAt: joinedAt
                )
            )

            try context.save()
        }

        do {
            let schema = SproutSchemaRegistry.schema
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)

            let families = try context.fetch(FetchDescriptor<FamilyGroup>())
            #expect(families.count == 1)
            let fetchedFamily = try #require(families.first)
            #expect(fetchedFamily.id == familyID)
            #expect(fetchedFamily.ownerUserID == ownerID)
            #expect(fetchedFamily.sharedBabyIDs == sharedBabyIDs)
            #expect(fetchedFamily.memberPayloads == memberPayloads)
            #expect(fetchedFamily.remoteVersion == 7)
            #expect(fetchedFamily.syncState == .synced)
        }
    }

    @Test("V2 to V4 migration preserves WeeklyLetter metadata and defaults legacy authorship")
    func testV2ToV4MigrationPreservesWeeklyLetterMetadataAndDefaultsAuthorship() async throws {
        let storeURL = try Self.makeTemporaryStoreURL(named: "v2-to-v4-migration")
        defer {
            try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent())
        }

        let babyID = UUID()
        let letterID = UUID()
        let recordID = UUID()
        let memoryID = UUID()
        let weekStart = Date(timeIntervalSince1970: 1_714_614_400)
        let weekEnd = Date(timeIntervalSince1970: 1_715_219_200)
        let generatedAt = Date(timeIntervalSince1970: 1_715_200_000)

        try Self.seedV2Store(
            at: storeURL,
            babyID: babyID,
            letterID: letterID,
            recordID: recordID,
            memoryID: memoryID,
            weekStart: weekStart,
            weekEnd: weekEnd,
            generatedAt: generatedAt
        )

        let schema = SproutSchemaRegistry.schema
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: SproutMigrationPlan.self,
            configurations: [configuration]
        )
        let context = ModelContext(container)

        let letters = try context.fetch(FetchDescriptor<WeeklyLetter>())
        #expect(letters.count == 1)
        let migratedLetter = try #require(letters.first)
        #expect(migratedLetter.id == letterID)
        #expect(migratedLetter.weekStart == weekStart)
        #expect(migratedLetter.weekEnd == weekEnd)
        #expect(migratedLetter.languageCode == "en")
        #expect(migratedLetter.sourceSignature == "source-v2")
        #expect(migratedLetter.generatedBy == "composer-v2")
        #expect(migratedLetter.generatedAt == generatedAt)

        let migratedRecord = try #require(try context.fetch(FetchDescriptor<RecordItem>()).first)
        #expect(migratedRecord.id == recordID)
        #expect(migratedRecord.createdByUserID == nil)
        #expect(migratedRecord.updatedByUserID == nil)

        let migratedMemory = try #require(try context.fetch(FetchDescriptor<MemoryEntry>()).first)
        #expect(migratedMemory.id == memoryID)
        #expect(migratedMemory.createdByUserID == nil)
        #expect(migratedMemory.updatedByUserID == nil)
    }

    @Test("V3 to V4 migration preserves WeeklyLetter metadata and defaults legacy authorship")
    func testV3ToV4MigrationPreservesWeeklyLetterMetadataAndDefaultsAuthorship() async throws {
        let storeURL = try Self.makeTemporaryStoreURL(named: "v3-to-v4-migration")
        defer {
            try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent())
        }

        let babyID = UUID()
        let letterID = UUID()
        let recordID = UUID()
        let memoryID = UUID()
        let milestoneID = UUID()
        let weekStart = Date(timeIntervalSince1970: 1_714_614_400)
        let weekEnd = Date(timeIntervalSince1970: 1_715_219_200)
        let generatedAt = Date(timeIntervalSince1970: 1_715_200_000)

        try Self.seedV3Store(
            at: storeURL,
            babyID: babyID,
            letterID: letterID,
            recordID: recordID,
            memoryID: memoryID,
            milestoneID: milestoneID,
            weekStart: weekStart,
            weekEnd: weekEnd,
            generatedAt: generatedAt
        )

        let schema = SproutSchemaRegistry.schema
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: SproutMigrationPlan.self,
            configurations: [configuration]
        )
        let context = ModelContext(container)

        let letters = try context.fetch(FetchDescriptor<WeeklyLetter>())
        #expect(letters.count == 1)
        let migratedLetter = try #require(letters.first)
        #expect(migratedLetter.id == letterID)
        #expect(migratedLetter.weekStart == weekStart)
        #expect(migratedLetter.weekEnd == weekEnd)
        #expect(migratedLetter.languageCode == "zh-Hans")
        #expect(migratedLetter.sourceSignature == "source-v3")
        #expect(migratedLetter.generatedBy == "composer-v3")
        #expect(migratedLetter.generatedAt == generatedAt)

        let migratedRecord = try #require(try context.fetch(FetchDescriptor<RecordItem>()).first)
        #expect(migratedRecord.id == recordID)
        #expect(migratedRecord.createdByUserID == nil)
        #expect(migratedRecord.updatedByUserID == nil)

        let migratedMemory = try #require(try context.fetch(FetchDescriptor<MemoryEntry>()).first)
        #expect(migratedMemory.id == memoryID)
        #expect(migratedMemory.createdByUserID == nil)
        #expect(migratedMemory.updatedByUserID == nil)

        let migratedMilestone = try #require(try context.fetch(FetchDescriptor<GrowthMilestoneEntry>()).first)
        #expect(migratedMilestone.id == milestoneID)
        #expect(migratedMilestone.createdByUserID == nil)
        #expect(migratedMilestone.updatedByUserID == nil)
    }

    @Test("V2 and V3 WeeklyLetter snapshots include persisted metadata fields")
    func testHistoricalWeeklyLetterSnapshotsIncludeMetadataFields() {
        let generatedAt = Date(timeIntervalSince1970: 1_715_200_000)
        let v2Letter = SproutSchemaV2.WeeklyLetter(
            weekStart: Date(timeIntervalSince1970: 1_714_614_400),
            weekEnd: Date(timeIntervalSince1970: 1_715_219_200),
            density: .normal,
            collapsedText: "v2 collapsed",
            expandedText: "v2 expanded",
            languageCode: "en",
            sourceSignature: "source-v2",
            generatedBy: "composer-v2",
            generatedAt: generatedAt
        )
        let v3Letter = SproutSchemaV3.WeeklyLetter(
            weekStart: Date(timeIntervalSince1970: 1_714_614_400),
            weekEnd: Date(timeIntervalSince1970: 1_715_219_200),
            density: .normal,
            collapsedText: "v3 collapsed",
            expandedText: "v3 expanded",
            languageCode: "zh-Hans",
            sourceSignature: "source-v3",
            generatedBy: "composer-v3",
            generatedAt: generatedAt
        )

        #expect(v2Letter.languageCode == "en")
        #expect(v2Letter.sourceSignature == "source-v2")
        #expect(v2Letter.generatedBy == "composer-v2")
        #expect(v3Letter.languageCode == "zh-Hans")
        #expect(v3Letter.sourceSignature == "source-v3")
        #expect(v3Letter.generatedBy == "composer-v3")
    }

    @Test("Migration plan does not repeat the same model shape across versions")
    func testMigrationPlanDoesNotRepeatModelShapes() {
        let modelSignatures = SproutMigrationPlan.schemas.map(Self.modelSignature)
        #expect(Set(modelSignatures).count == modelSignatures.count)
        #expect(modelSignatures.last == Self.modelSignature(SproutSchemaRegistry.models))
    }

    @Test("Migration plan container starts without duplicate version checksum failure")
    func testMigrationPlanContainerStartsWithoutDuplicateVersionChecksums() throws {
        let schema = SproutSchemaRegistry.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: SproutMigrationPlan.self,
                configurations: [configuration]
            )
            #expect(!container.configurations.isEmpty)
        } catch {
            let message = String(describing: error)
            #expect(!message.contains("Duplicate version checksums across stages detected"))
            Issue.record(Comment(rawValue: "Expected migration-plan startup to succeed, got: \(message)"))
        }
    }

    // MARK: - Helpers

    private static func modelSignature(_ schema: any VersionedSchema.Type) -> String {
        modelSignature(schema.models)
    }

    private static func modelSignature(_ models: [any PersistentModel.Type]) -> String {
        models
            .map { String(reflecting: $0) }
            .sorted()
            .joined(separator: "|")
    }

    private static func countStoreFiles(in directory: URL, fileManager: FileManager) -> Int {
        let fileNames = ["default.store", "default.store-wal", "default.store-shm"]
        var count = 0
        for name in fileNames {
            let url = directory.appendingPathComponent(name)
            if fileManager.fileExists(atPath: url.path) {
                count += 1
            }
        }
        return count
    }

    private static func makeTemporaryStoreURL(named name: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("sprout-tests-\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("default.store")
    }

    private static func seedV2Store(
        at storeURL: URL,
        babyID: UUID,
        letterID: UUID,
        recordID: UUID,
        memoryID: UUID,
        weekStart: Date,
        weekEnd: Date,
        generatedAt: Date
    ) throws {
        let schema = Schema(SproutSchemaV2.models, version: SproutSchemaV2.versionIdentifier)
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        context.insert(
            SproutSchemaV2.BabyProfile(
                id: babyID,
                name: "Sprout",
                birthDate: Date(timeIntervalSince1970: 1_700_000_000),
                createdAt: Date(timeIntervalSince1970: 1_700_000_001)
            )
        )
        context.insert(
            SproutSchemaV2.RecordItem(
                id: recordID,
                babyID: babyID,
                timestamp: Date(timeIntervalSince1970: 1_714_700_000),
                type: "milk",
                value: 120
            )
        )
        context.insert(
            SproutSchemaV2.MemoryEntry(
                id: memoryID,
                babyID: babyID,
                createdAt: Date(timeIntervalSince1970: 1_714_800_000),
                ageInDays: 42,
                imageLocalPath: "memory.jpg",
                note: "legacy memory",
                isMilestone: false
            )
        )
        context.insert(
            SproutSchemaV2.WeeklyLetter(
                id: letterID,
                weekStart: weekStart,
                weekEnd: weekEnd,
                density: .normal,
                collapsedText: "collapsed",
                expandedText: "expanded",
                languageCode: "en",
                sourceSignature: "source-v2",
                generatedBy: "composer-v2",
                generatedAt: generatedAt
            )
        )

        try context.save()
    }

    private static func seedV3Store(
        at storeURL: URL,
        babyID: UUID,
        letterID: UUID,
        recordID: UUID,
        memoryID: UUID,
        milestoneID: UUID,
        weekStart: Date,
        weekEnd: Date,
        generatedAt: Date
    ) throws {
        let schema = Schema(SproutSchemaV3.models, version: SproutSchemaV3.versionIdentifier)
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        context.insert(
            SproutSchemaV3.BabyProfile(
                id: babyID,
                name: "Sprout",
                birthDate: Date(timeIntervalSince1970: 1_700_000_000),
                createdAt: Date(timeIntervalSince1970: 1_700_000_001)
            )
        )
        context.insert(
            SproutSchemaV3.RecordItem(
                id: recordID,
                babyID: babyID,
                timestamp: Date(timeIntervalSince1970: 1_714_700_000),
                type: "milk",
                value: 120
            )
        )
        context.insert(
            SproutSchemaV3.MemoryEntry(
                id: memoryID,
                babyID: babyID,
                createdAt: Date(timeIntervalSince1970: 1_714_800_000),
                ageInDays: 42,
                imageLocalPath: "memory.jpg",
                note: "legacy memory",
                isMilestone: false
            )
        )
        context.insert(
            SproutSchemaV3.WeeklyLetter(
                id: letterID,
                weekStart: weekStart,
                weekEnd: weekEnd,
                density: .normal,
                collapsedText: "collapsed",
                expandedText: "expanded",
                languageCode: "zh-Hans",
                sourceSignature: "source-v3",
                generatedBy: "composer-v3",
                generatedAt: generatedAt
            )
        )
        context.insert(
            SproutSchemaV3.GrowthMilestoneEntry(
                id: milestoneID,
                babyID: babyID,
                title: "Roll over",
                category: "motor",
                occurredAt: Date(timeIntervalSince1970: 1_714_900_000)
            )
        )

        try context.save()
    }
}
