import Foundation
import Testing
import SwiftData
@testable import sprout

@MainActor
struct BabyRepositoryTests {

    @Test("createDefaultIfNeeded creates a baby when none exist")
    func testCreateDefault() async throws {
        let env = try makeTestEnvironment(now: .now)
        let repo = env.makeBabyRepository()

        repo.createDefaultIfNeeded()

        let baby = repo.activeBaby
        #expect(baby != nil)
        #expect(baby?.isActive == true)
        #expect(baby?.gender == nil)
    }

    @Test("createDefaultIfNeeded does not duplicate when baby exists")
    func testNoDuplicate() async throws {
        let env = try makeTestEnvironment(now: .now)
        let repo = env.makeBabyRepository()

        repo.createDefaultIfNeeded()
        repo.createDefaultIfNeeded()

        let descriptor = FetchDescriptor<BabyProfile>()
        let babies = try env.modelContext.fetch(descriptor)
        #expect(babies.count == 1)
    }

    @Test("updateName persists change")
    func testUpdateName() async throws {
        let env = try makeTestEnvironment(now: .now)
        let repo = env.makeBabyRepository()
        repo.createDefaultIfNeeded()

        repo.updateName("小花生")

        #expect(repo.activeBaby?.name == "小花生")
    }

    @Test("updateBirthDate persists change")
    func testUpdateBirthDate() async throws {
        let env = try makeTestEnvironment(now: .now)
        let repo = env.makeBabyRepository()
        repo.createDefaultIfNeeded()

        let newDate = Date(timeIntervalSinceNow: -86400 * 100)
        repo.updateBirthDate(newDate)

        #expect(repo.activeBaby?.birthDate != nil)
    }

    @Test("updateGender persists change")
    func testUpdateGender() async throws {
        let env = try makeTestEnvironment(now: .now)
        let repo = env.makeBabyRepository()
        repo.createDefaultIfNeeded()

        repo.updateGender(.male)
        #expect(repo.activeBaby?.gender == .male)

        repo.updateGender(nil)
        #expect(repo.activeBaby?.gender == nil)
    }

    @Test("activeBaby returns nil when no babies exist")
    func testActiveBabyNil() async throws {
        let env = try makeTestEnvironment(now: .now)
        let repo = env.makeBabyRepository()

        #expect(repo.activeBaby == nil)
    }
}
