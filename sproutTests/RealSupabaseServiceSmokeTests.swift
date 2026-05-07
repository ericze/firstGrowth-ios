import Foundation
import Testing
@testable import sprout

@MainActor
struct RealSupabaseServiceSmokeTests {
    @Test("real Supabase auth smoke is gated by environment")
    func realAuthSmoke() async throws {
        guard let credentials = try smokeCredentials() else {
            return
        }

        let service = try makeService(credentials: credentials)

        let session = try await service.signIn(email: credentials.email, password: credentials.password)
        #expect(session.user.email == credentials.email)
        try await service.signOut()
    }

    @Test("real Supabase data chain smoke is gated by environment")
    func realDataChainSmoke() async throws {
        guard let credentials = try smokeCredentials() else {
            return
        }

        let service = try makeService(credentials: credentials)
        let session = try await service.signIn(email: credentials.email, password: credentials.password)

        do {
            let userID = session.user.id
            let stamp = UUID().uuidString
            let babyID = UUID()
            let recordID = UUID()
            let memoryID = UUID()
            let familyGroupID = UUID()
            let now = Date()
            let assetPath = "\(userID.uuidString)/smoke/\(stamp).txt"
            let assetData = Data("sprout smoke \(stamp)".utf8)

            _ = try await service.fetchServerNow()
            try await deleteExistingFamilyGroups(service: service)

            let profile = BabyProfileDTO(
                id: babyID,
                userID: userID,
                name: "Smoke Baby \(stamp.prefix(8))",
                birthDate: now.addingTimeInterval(-180 * 24 * 60 * 60),
                gender: nil,
                avatarStoragePath: assetPath,
                isActive: true,
                hasCompletedOnboarding: true,
                createdAt: now,
                updatedAt: now,
                version: 1,
                deletedAt: nil
            )
            let savedProfile = try await service.upsertBabyProfile(profile, expectedVersion: nil)
            #expect(savedProfile.id == babyID)
            #expect(savedProfile.userID == userID)
            #expect(savedProfile.version == 1)

            let familyGroup = FamilyGroupDTO(
                id: familyGroupID,
                ownerUserID: userID,
                inviteCode: "SMOKE-\(stamp.prefix(8).uppercased())",
                inviteExpiresAt: now.addingTimeInterval(24 * 60 * 60),
                inviteState: FamilyInviteState.active.rawValue,
                sharedBabyIDs: [babyID],
                members: [
                    FamilyMemberSnapshot(
                        userID: userID,
                        role: .owner,
                        joinedAt: now,
                        removedAt: nil
                    )
                ],
                createdAt: now,
                updatedAt: now,
                version: 1,
                deletedAt: nil
            )
            let savedFamilyGroup = try await service.upsertFamilyGroup(familyGroup, expectedVersion: nil)
            #expect(savedFamilyGroup.id == familyGroupID)
            #expect(savedFamilyGroup.ownerUserID == userID)
            #expect(savedFamilyGroup.sharedBabyIDs == [babyID])
            #expect(savedFamilyGroup.members == familyGroup.members)
            #expect(savedFamilyGroup.version == 1)

            let record = RecordItemDTO(
                id: recordID,
                userID: userID,
                babyID: babyID,
                type: "feeding",
                timestamp: now,
                value: 120,
                leftNursingSeconds: 0,
                rightNursingSeconds: 0,
                subType: "formula",
                imageStoragePath: nil,
                aiSummary: nil,
                tags: ["smoke"],
                note: "Supabase data chain smoke",
                createdAt: now,
                updatedAt: now,
                version: 1,
                deletedAt: nil
            )
            let savedRecord = try await service.upsertRecordItem(record, expectedVersion: nil)
            #expect(savedRecord.id == recordID)
            #expect(savedRecord.babyID == babyID)
            #expect(savedRecord.version == 1)

            let memory = MemoryEntryDTO(
                id: memoryID,
                userID: userID,
                babyID: babyID,
                createdAt: now,
                ageInDays: 180,
                imageStoragePaths: [assetPath],
                note: "Supabase memory smoke",
                isMilestone: false,
                updatedAt: now,
                version: 1,
                deletedAt: nil
            )
            let savedMemory = try await service.upsertMemoryEntry(memory, expectedVersion: nil)
            #expect(savedMemory.id == memoryID)
            #expect(savedMemory.babyID == babyID)
            #expect(savedMemory.version == 1)

            let upperBound = try await service.fetchServerNow()
            let fetchedProfiles = try await service.fetchBabyProfiles(updatedAfter: nil, upTo: upperBound)
            let fetchedRecords = try await service.fetchRecordItems(updatedAfter: nil, upTo: upperBound)
            let fetchedMemories = try await service.fetchMemoryEntries(updatedAfter: nil, upTo: upperBound)
            let fetchedFamilyGroups = try await service.fetchFamilyGroups(updatedAfter: nil, upTo: upperBound)
            #expect(fetchedProfiles.contains { $0.id == babyID && $0.name == savedProfile.name })
            #expect(fetchedRecords.contains { $0.id == recordID && $0.note == savedRecord.note })
            #expect(fetchedMemories.contains { $0.id == memoryID && $0.note == savedMemory.note })
            #expect(fetchedFamilyGroups.contains { $0.id == familyGroupID && $0.inviteCode == savedFamilyGroup.inviteCode })

            let updatedFamilyGroup = FamilyGroupDTO(
                id: familyGroupID,
                ownerUserID: userID,
                inviteCode: savedFamilyGroup.inviteCode,
                inviteExpiresAt: savedFamilyGroup.inviteExpiresAt,
                inviteState: FamilyInviteState.revoked.rawValue,
                sharedBabyIDs: [],
                members: savedFamilyGroup.members,
                createdAt: savedFamilyGroup.createdAt,
                updatedAt: now.addingTimeInterval(60),
                version: savedFamilyGroup.version,
                deletedAt: nil
            )
            let savedUpdatedFamilyGroup = try await service.upsertFamilyGroup(
                updatedFamilyGroup,
                expectedVersion: savedFamilyGroup.version
            )
            #expect(savedUpdatedFamilyGroup.id == familyGroupID)
            #expect(savedUpdatedFamilyGroup.inviteState == FamilyInviteState.revoked.rawValue)
            #expect(savedUpdatedFamilyGroup.sharedBabyIDs.isEmpty)
            #expect(savedUpdatedFamilyGroup.version == savedFamilyGroup.version + 1)

            try await service.uploadAsset(data: assetData, bucket: .babyAvatars, path: assetPath, contentType: "text/plain")
            let downloadedAsset = try await service.downloadAsset(bucket: .babyAvatars, path: assetPath)
            #expect(downloadedAsset == assetData)
            try await service.deleteAsset(bucket: .babyAvatars, path: assetPath)

            try await service.softDelete(
                table: .familyGroups,
                id: familyGroupID,
                expectedVersion: savedUpdatedFamilyGroup.version
            )
            try await service.softDelete(table: .recordItems, id: recordID, expectedVersion: savedRecord.version)
            try await service.softDelete(table: .memoryEntries, id: memoryID, expectedVersion: savedMemory.version)
            try await service.softDelete(table: .babyProfiles, id: babyID, expectedVersion: savedProfile.version)

            let deletedUpperBound = try await service.fetchServerNow()
            let deletedProfiles = try await service.fetchBabyProfiles(updatedAfter: upperBound, upTo: deletedUpperBound)
            let deletedRecords = try await service.fetchRecordItems(updatedAfter: upperBound, upTo: deletedUpperBound)
            let deletedMemories = try await service.fetchMemoryEntries(updatedAfter: upperBound, upTo: deletedUpperBound)
            let deletedFamilyGroups = try await service.fetchFamilyGroups(updatedAfter: upperBound, upTo: deletedUpperBound)
            #expect(deletedProfiles.contains { $0.id == babyID && $0.deletedAt != nil })
            #expect(deletedRecords.contains { $0.id == recordID && $0.deletedAt != nil })
            #expect(deletedMemories.contains { $0.id == memoryID && $0.deletedAt != nil })
            #expect(deletedFamilyGroups.contains { $0.id == familyGroupID && $0.deletedAt != nil })

            try await service.signOut()
        } catch {
            try? await service.signOut()
            throw error
        }
    }

    private func smokeCredentials() throws -> SmokeCredentials? {
        let environment = ProcessInfo.processInfo.environment
        guard environment["SPROUT_REAL_SUPABASE_SMOKE"] == "1" else {
            return nil
        }

        return SmokeCredentials(
            url: try #require(environment["SPROUT_SUPABASE_URL"]),
            anonKey: try #require(environment["SPROUT_SUPABASE_ANON_KEY"]),
            email: try #require(environment["SPROUT_SUPABASE_TEST_EMAIL"]),
            password: try #require(environment["SPROUT_SUPABASE_TEST_PASSWORD"])
        )
    }

    private func makeService(credentials: SmokeCredentials) throws -> SupabaseService {
        try SupabaseService(
            config: SupabaseConfig(
                infoDictionary: [
                    SupabaseConfig.urlKey: credentials.url,
                    SupabaseConfig.anonKeyKey: credentials.anonKey
                ]
            )
        )
    }

    private func deleteExistingFamilyGroups(service: SupabaseService) async throws {
        let upperBound = try await service.fetchServerNow()
        let existingGroups = try await service.fetchFamilyGroups(updatedAfter: nil, upTo: upperBound)

        for group in existingGroups where group.deletedAt == nil {
            try await service.softDelete(
                table: .familyGroups,
                id: group.id,
                expectedVersion: group.version
            )
        }
    }
}

private struct SmokeCredentials {
    let url: String
    let anonKey: String
    let email: String
    let password: String
}
