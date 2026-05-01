import Foundation
import Testing
import SwiftData
@testable import sprout

@MainActor
struct GrowthMilestoneRepositoryTests {

    @Test("create milestone uses active baby ID and marks pending upsert")
    func testCreateMilestoneUsesActiveBabyIDAndMarksPendingUpsert() throws {
        let env = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let activeBabyID = UUID()
        let baby = BabyProfile(
            id: activeBabyID,
            name: "Active",
            birthDate: env.now.value.addingTimeInterval(-86_400),
            createdAt: env.now.value.addingTimeInterval(-3_600),
            isActive: true
        )
        env.modelContext.insert(baby)
        try env.modelContext.save()

        let repo = GrowthMilestoneRepository(modelContext: env.modelContext)
        let entry = try repo.createMilestone(
            babyID: activeBabyID,
            title: "First Smile",
            templateKey: GrowthMilestoneTemplate.firstSmile.rawValue,
            category: GrowthMilestoneCategory.social.rawValue,
            occurredAt: env.now.value,
            note: "Smiled at daddy"
        )

        #expect(entry.babyID == activeBabyID)
        #expect(entry.title == "First Smile")
        #expect(entry.templateKey == GrowthMilestoneTemplate.firstSmile.rawValue)
        #expect(entry.category == GrowthMilestoneCategory.social.rawValue)
        #expect(entry.syncState == .pendingUpsert)
        #expect(entry.isCustom == false)
        #expect(entry.note == "Smiled at daddy")
    }

    @Test("create milestone stamps current user authorship when available")
    func testCreateMilestoneStampsCurrentUserAuthorshipWhenAvailable() throws {
        let currentUserID = UUID()
        let env = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let babyID = UUID()
        let repo = GrowthMilestoneRepository(
            modelContext: env.modelContext,
            currentUserIDProvider: { currentUserID }
        )

        let entry = try repo.createMilestone(
            babyID: babyID,
            title: "First Smile",
            category: GrowthMilestoneCategory.social.rawValue,
            occurredAt: env.now.value
        )

        #expect(entry.createdByUserID == currentUserID)
        #expect(entry.updatedByUserID == currentUserID)
    }

    @Test("shared milestone rejects update from non-author")
    func testSharedMilestoneRejectsUpdateFromNonAuthor() throws {
        let ownerID = UUID()
        let currentUserID = UUID()
        let authorID = UUID()
        let babyID = UUID()
        let env = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let repo = GrowthMilestoneRepository(
            modelContext: env.modelContext,
            currentUserIDProvider: { currentUserID },
            accessProvider: { requestedBabyID in
                requestedBabyID == babyID ? FamilyBabyAccess(babyID: babyID, ownership: .shared(ownerUserID: ownerID)) : nil
            }
        )
        let entry = GrowthMilestoneEntry(
            babyID: babyID,
            title: "First Smile",
            category: GrowthMilestoneCategory.social.rawValue,
            occurredAt: env.now.value,
            createdByUserID: authorID,
            updatedByUserID: authorID
        )
        env.modelContext.insert(entry)
        try env.modelContext.save()

        #expect(throws: GrowthMilestoneRepositoryError.permissionDenied(entry.id)) {
            try repo.updateMilestone(entry, title: "Big Smile")
        }
        #expect(entry.title == "First Smile")
        #expect(entry.updatedByUserID == authorID)
    }

    @Test("shared milestone rejects delete from non-author")
    func testSharedMilestoneRejectsDeleteFromNonAuthor() throws {
        let ownerID = UUID()
        let currentUserID = UUID()
        let authorID = UUID()
        let babyID = UUID()
        let env = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let repo = GrowthMilestoneRepository(
            modelContext: env.modelContext,
            currentUserIDProvider: { currentUserID },
            accessProvider: { requestedBabyID in
                requestedBabyID == babyID ? FamilyBabyAccess(babyID: babyID, ownership: .shared(ownerUserID: ownerID)) : nil
            }
        )
        let entry = GrowthMilestoneEntry(
            babyID: babyID,
            title: "First Tooth",
            category: GrowthMilestoneCategory.cognitive.rawValue,
            occurredAt: env.now.value,
            createdByUserID: authorID,
            updatedByUserID: authorID
        )
        env.modelContext.insert(entry)
        try env.modelContext.save()

        #expect(throws: GrowthMilestoneRepositoryError.permissionDenied(entry.id)) {
            try repo.deleteMilestone(id: entry.id)
        }
        #expect(try repo.fetchMilestone(id: entry.id) != nil)
    }

    @Test("shared milestone allows author update and delete")
    func testSharedMilestoneAllowsAuthorUpdateAndDelete() throws {
        let ownerID = UUID()
        let currentUserID = UUID()
        let babyID = UUID()
        let env = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let repo = GrowthMilestoneRepository(
            modelContext: env.modelContext,
            currentUserIDProvider: { currentUserID },
            accessProvider: { requestedBabyID in
                requestedBabyID == babyID ? FamilyBabyAccess(babyID: babyID, ownership: .shared(ownerUserID: ownerID)) : nil
            }
        )
        let entry = GrowthMilestoneEntry(
            babyID: babyID,
            title: "First Smile",
            category: GrowthMilestoneCategory.social.rawValue,
            occurredAt: env.now.value,
            createdByUserID: currentUserID,
            updatedByUserID: currentUserID
        )
        env.modelContext.insert(entry)
        try env.modelContext.save()

        try repo.updateMilestone(entry, title: "Big Smile")
        #expect(entry.title == "Big Smile")
        #expect(entry.updatedByUserID == currentUserID)

        try repo.deleteMilestone(id: entry.id)
        #expect(try repo.fetchMilestone(id: entry.id) == nil)
    }

    @Test("fetch milestones returns reverse chronological order")
    func testFetchMilestonesReturnsReverseChronologicalOrder() throws {
        let env = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let babyID = UUID()
        let repo = GrowthMilestoneRepository(modelContext: env.modelContext)

        let dates: [Date] = [
            env.now.value.addingTimeInterval(-86_400 * 10),
            env.now.value.addingTimeInterval(-86_400 * 5),
            env.now.value.addingTimeInterval(-86_400 * 1),
        ]

        for (index, date) in dates.enumerated() {
            try repo.createMilestone(
                babyID: babyID,
                title: "Milestone \(index)",
                category: GrowthMilestoneCategory.motor.rawValue,
                occurredAt: date
            )
        }

        let fetched = try repo.fetchMilestones(for: babyID)
        #expect(fetched.count == 3)
        #expect(fetched[0].occurredAt > fetched[1].occurredAt)
        #expect(fetched[1].occurredAt > fetched[2].occurredAt)
        #expect(fetched[0].title == "Milestone 2")
        #expect(fetched[2].title == "Milestone 0")
    }

    @Test("delete milestone removes the entry")
    func testDeleteMilestoneRemovesEntry() throws {
        let env = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let babyID = UUID()
        let repo = GrowthMilestoneRepository(modelContext: env.modelContext)

        let entry = try repo.createMilestone(
            babyID: babyID,
            title: "First Tooth",
            category: GrowthMilestoneCategory.cognitive.rawValue,
            occurredAt: env.now.value
        )

        #expect(try repo.fetchMilestone(id: entry.id) != nil)

        try repo.deleteMilestone(id: entry.id)

        #expect(try repo.fetchMilestone(id: entry.id) == nil)
    }

    @Test("update milestone marks pending upsert and updates timestamp")
    func testUpdateMilestone() throws {
        let env = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let babyID = UUID()
        let repo = GrowthMilestoneRepository(modelContext: env.modelContext)

        let entry = try repo.createMilestone(
            babyID: babyID,
            title: "First Smile",
            category: GrowthMilestoneCategory.social.rawValue,
            occurredAt: env.now.value
        )

        let originalUpdatedAt = entry.updatedAt

        // Advance time so updatedAt differs
        env.now.value = env.now.value.addingTimeInterval(60)

        let newDate = env.now.value.addingTimeInterval(-86_400)
        try repo.updateMilestone(
            entry,
            title: "Big Smile",
            note: "Updated note",
            occurredAt: newDate
        )

        #expect(entry.title == "Big Smile")
        #expect(entry.note == "Updated note")
        #expect(entry.occurredAt == newDate)
        #expect(entry.syncState == .pendingUpsert)
        #expect(entry.updatedAt > originalUpdatedAt)
    }
}
