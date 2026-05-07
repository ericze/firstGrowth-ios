import Foundation
import SwiftData
import Testing

@testable import sprout

@MainActor
struct BabyRepositoryTests {

  @Test("createDefaultIfNeeded creates a baby when none exist")
  func testCreateDefault() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()

    #expect(repo.createDefaultIfNeeded() == true)

    let baby = repo.activeBaby
    #expect(baby != nil)
    #expect(baby?.isActive == true)
    #expect(baby?.gender == nil)
    #expect(baby?.syncState == .pendingUpsert)
  }

  @Test("createDefaultIfNeeded does not duplicate when baby exists")
  func testNoDuplicate() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()

    #expect(repo.createDefaultIfNeeded() == true)
    #expect(repo.createDefaultIfNeeded() == true)

    let descriptor = FetchDescriptor<BabyProfile>()
    let babies = try env.modelContext.fetch(descriptor)
    #expect(babies.count == 1)
  }

  @Test("updateName persists change")
  func testUpdateName() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    #expect(repo.createDefaultIfNeeded() == true)

    #expect(repo.updateName("小花生") == true)

    #expect(repo.activeBaby?.name == "小花生")
    #expect(repo.activeBaby?.syncState == .pendingUpsert)
  }

  @Test("updateBirthDate persists change")
  func testUpdateBirthDate() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    #expect(repo.createDefaultIfNeeded() == true)

    let newDate = Date(timeIntervalSinceNow: -86400 * 100)
    #expect(repo.updateBirthDate(newDate) == true)

    #expect(repo.activeBaby?.birthDate == newDate)
    #expect(repo.activeBaby?.syncState == .pendingUpsert)
  }

  @Test("updateGender persists change")
  func testUpdateGender() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    #expect(repo.createDefaultIfNeeded() == true)

    #expect(repo.updateGender(.male) == true)
    #expect(repo.activeBaby?.gender == .male)
    #expect(repo.activeBaby?.syncState == .pendingUpsert)

    #expect(repo.updateGender(nil) == true)
    #expect(repo.activeBaby?.gender == nil)
    #expect(repo.activeBaby?.syncState == .pendingUpsert)
  }

  @Test("activeBaby returns nil when no babies exist")
  func testActiveBabyNil() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()

    #expect(repo.activeBaby == nil)
  }

  @Test("updateName syncs to ActiveBabyState")
  func testUpdateNameSyncsState() async throws {
    let env = try makeTestEnvironment(now: .now)
    let state = ActiveBabyState()
    let repo = env.makeBabyRepository(activeBabyState: state)
    #expect(repo.createDefaultIfNeeded() == true)
    state.updateFrom(repo.activeBaby)

    #expect(repo.updateName("小花生") == true)

    #expect(state.headerConfig.babyName == "小花生")
  }

  @Test("updateBirthDate syncs to ActiveBabyState")
  func testUpdateBirthDateSyncsState() async throws {
    let env = try makeTestEnvironment(now: .now)
    let state = ActiveBabyState()
    let repo = env.makeBabyRepository(activeBabyState: state)
    #expect(repo.createDefaultIfNeeded() == true)
    state.updateFrom(repo.activeBaby)

    let newDate = Date(timeIntervalSinceNow: -86400 * 200)
    #expect(repo.updateBirthDate(newDate) == true)

    #expect(state.headerConfig.birthDate == newDate)
  }

  @Test("updateGender syncs to ActiveBabyState via headerConfig")
  func testUpdateGenderSyncsState() async throws {
    let env = try makeTestEnvironment(now: .now)
    let state = ActiveBabyState()
    let repo = env.makeBabyRepository(activeBabyState: state)
    #expect(repo.createDefaultIfNeeded() == true)
    state.updateFrom(repo.activeBaby)

    let originalName = state.headerConfig.babyName
    #expect(repo.updateGender(.male) == true)

    #expect(state.headerConfig.babyName == originalName)
  }

  @Test("updateName without ActiveBabyState does not crash")
  func testUpdateNameWithoutState() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    #expect(repo.createDefaultIfNeeded() == true)

    #expect(repo.updateName("安全测试") == true)
    #expect(repo.activeBaby?.name == "安全测试")
  }

  @Test("markOnboardingCompleted persists explicit completion state")
  func testMarkOnboardingCompleted() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    #expect(repo.createDefaultIfNeeded() == true)

    #expect(repo.markOnboardingCompleted() == true)

    #expect(repo.activeBaby?.hasCompletedOnboarding == true)
    #expect(repo.activeBaby?.syncState == .pendingUpsert)
  }

  @Test("createBaby creates a second active baby and deactivates the previous one")
  func testCreateSecondBabyActivatesNewBaby() async throws {
    let env = try makeTestEnvironment(now: .now)
    let state = ActiveBabyState()
    let repo = env.makeBabyRepository(activeBabyState: state)
    #expect(repo.createDefaultIfNeeded() == true)
    let firstBaby = try #require(repo.activeBaby)

    let secondBaby = try #require(repo.createBaby(name: "小栗子", birthDate: env.now.value))

    let babies = try repo.fetchBabies()
    #expect(babies.count == 2)
    #expect(secondBaby.isActive == true)
    #expect(firstBaby.isActive == false)
    #expect(repo.activeBaby?.id == secondBaby.id)
    #expect(state.headerConfig.babyID == secondBaby.id)
  }

  @Test("free entitlement keeps the first baby but blocks creating a second baby")
  func freeEntitlementBlocksSecondBabyWithoutDeletingExistingData() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = BabyRepository(
      modelContext: env.modelContext,
      canCreateAdditionalBaby: { existingBabyCount in existingBabyCount == 0 }
    )
    #expect(repo.createDefaultIfNeeded() == true)
    let firstBaby = try #require(repo.activeBaby)

    let secondBaby = repo.createBaby(name: "小栗子", birthDate: env.now.value)

    let babies = try repo.fetchBabies()
    #expect(secondBaby == nil)
    #expect(babies.count == 1)
    #expect(babies.first?.id == firstBaby.id)
    #expect(babies.first?.name == firstBaby.name)
  }

  @Test("typed create result exposes entitlement-blocked failure reason")
  func createBabyResultExposesEntitlementBlockedFailureReason() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = BabyRepository(
      modelContext: env.modelContext,
      canCreateAdditionalBaby: { existingBabyCount in existingBabyCount == 0 }
    )
    #expect(repo.createDefaultIfNeeded() == true)

    let result = repo.createBabyResult(name: "小栗子", birthDate: env.now.value)

    switch result {
    case .success:
      Issue.record("Expected entitlement-blocked failure, but createBabyResult succeeded")
    case .failure(let failure):
      #expect(failure == .entitlementBlocked)
    }
  }

  @Test("expired entitlement preserves existing babies but blocks adding another")
  func expiredEntitlementBlocksAdditionalBabyWithoutDeletingExistingData() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    #expect(repo.createDefaultIfNeeded() == true)
    let secondBaby = try #require(repo.createBaby(name: "小栗子", birthDate: env.now.value))

    let expiredRepo = BabyRepository(
      modelContext: env.modelContext,
      canCreateAdditionalBaby: { _ in false }
    )
    let thirdBaby = expiredRepo.createBaby(name: "小松果", birthDate: env.now.value)

    let babies = try expiredRepo.fetchBabies()
    #expect(thirdBaby == nil)
    #expect(babies.count == 2)
    #expect(babies.contains { $0.id == secondBaby.id })
  }

  @Test("createBabyResult normalizes blank names to the default placeholder")
  func createBabyResultFallsBackToDefaultPlaceholderName() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()

    let result = repo.createBabyResult(name: "  \n\t  ", birthDate: env.now.value)

    let baby: BabyProfile
    switch result {
    case .success(let createdBaby):
      baby = createdBaby
    case .failure(let failure):
      Issue.record("Expected createBabyResult to succeed, got failure: \(failure)")
      return
    }

    #expect(baby.name == BabyProfile.defaultName)
    #expect(baby.isActive == true)
  }

  @Test("deleteBabyResult removes an inactive baby and writes a tombstone")
  func deleteBabyResultRemovesInactiveBabyAndWritesTombstone() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    #expect(repo.createDefaultIfNeeded() == true)
    let firstBaby = try #require(repo.activeBaby)
    let secondBaby = try #require(repo.createBaby(name: "小栗子", birthDate: env.now.value))

    let result = repo.deleteBabyResult(id: firstBaby.id)

    switch result {
    case .success:
      break
    case .failure(let failure):
      Issue.record("Expected deleteBabyResult to succeed, got failure: \(failure)")
      return
    }

    let babies = try repo.fetchBabies()
    #expect(babies.count == 1)
    #expect(babies.first?.id == secondBaby.id)

    let tombstones = try env.modelContext.fetch(FetchDescriptor<SyncDeletionTombstone>())
    #expect(tombstones.count == 1)
    #expect(tombstones.first?.entityType == .babyProfile)
    #expect(tombstones.first?.entityID == firstBaby.id)
  }

  @Test("deleteBabyResult removes the deleted baby's local avatar file")
  func deleteBabyResultRemovesDeletedBabyAvatarFile() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    #expect(repo.createDefaultIfNeeded() == true)
    let firstBaby = try #require(repo.activeBaby)
    _ = try #require(repo.createBaby(name: "小栗子", birthDate: env.now.value))
    let avatarURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("sprout-avatar-\(UUID().uuidString).jpg")
    try Data([0xFF, 0xD8, 0xFF, 0xD9]).write(to: avatarURL, options: .atomic)
    firstBaby.avatarPath = avatarURL.path
    try env.modelContext.save()

    let result = repo.deleteBabyResult(id: firstBaby.id)

    switch result {
    case .success:
      break
    case .failure(let failure):
      Issue.record("Expected deleteBabyResult to succeed, got failure: \(failure)")
      return
    }

    #expect(FileManager.default.fileExists(atPath: avatarURL.path) == false)
  }

  @Test("deleteBabyResult switches active baby when deleting the current baby")
  func deleteBabyResultSwitchesActiveBabyWhenDeletingCurrentBaby() async throws {
    let env = try makeTestEnvironment(now: .now)
    let state = ActiveBabyState()
    let repo = env.makeBabyRepository(activeBabyState: state)
    #expect(repo.createDefaultIfNeeded() == true)
    let firstBaby = try #require(repo.activeBaby)
    let secondBaby = try #require(repo.createBaby(name: "小栗子", birthDate: env.now.value))
    #expect(repo.activateBaby(id: firstBaby.id) == true)

    let result = repo.deleteBabyResult(id: firstBaby.id)

    switch result {
    case .success(let outcome):
      #expect(outcome.activeBabyID == secondBaby.id)
    case .failure(let failure):
      Issue.record("Expected deleteBabyResult to succeed, got failure: \(failure)")
      return
    }

    let babies = try repo.fetchBabies()
    #expect(babies.count == 1)
    #expect(babies.first?.id == secondBaby.id)
    #expect(repo.activeBaby?.id == secondBaby.id)
    #expect(state.headerConfig.babyID == secondBaby.id)
  }

  @Test("deleteBabyResult blocks removing the last remaining baby")
  func deleteBabyResultBlocksRemovingLastRemainingBaby() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    #expect(repo.createDefaultIfNeeded() == true)
    let baby = try #require(repo.activeBaby)

    let result = repo.deleteBabyResult(id: baby.id)

    switch result {
    case .success:
      Issue.record("Expected deleteBabyResult to fail for the last remaining baby")
    case .failure(let failure):
      #expect(failure == .onlyRemainingBaby)
    }

    let babies = try repo.fetchBabies()
    #expect(babies.count == 1)
    #expect(babies.first?.id == baby.id)
  }

  @Test("deleteBabyResult blocks removing a baby that still has associated data")
  func deleteBabyResultBlocksRemovingBabyWithAssociatedData() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    #expect(repo.createDefaultIfNeeded() == true)
    let firstBaby = try #require(repo.activeBaby)
    _ = try #require(repo.createBaby(name: "小栗子", birthDate: env.now.value))

    let record = RecordItem(
      babyID: firstBaby.id,
      timestamp: env.now.value,
      type: RecordType.milk.rawValue
    )
    env.modelContext.insert(record)
    try env.modelContext.save()

    let result = repo.deleteBabyResult(id: firstBaby.id)

    switch result {
    case .success:
      Issue.record("Expected deleteBabyResult to fail when associated data still exists")
    case .failure(let failure):
      #expect(failure == .hasAssociatedData)
    }

    let babies = try repo.fetchBabies()
    #expect(babies.contains { $0.id == firstBaby.id })
    let tombstones = try env.modelContext.fetch(FetchDescriptor<SyncDeletionTombstone>())
    #expect(tombstones.isEmpty)
  }

  @Test("activateBaby switches the active baby and syncs header state")
  func testActivateBabySwitchesActiveBaby() async throws {
    let env = try makeTestEnvironment(now: .now)
    let state = ActiveBabyState()
    let repo = env.makeBabyRepository(activeBabyState: state)
    #expect(repo.createDefaultIfNeeded() == true)
    let firstBaby = try #require(repo.activeBaby)
    _ = try #require(repo.createBaby(name: "小栗子", birthDate: env.now.value))

    #expect(repo.activateBaby(id: firstBaby.id) == true)

    let babies = try repo.fetchBabies()
    #expect(babies.first { $0.id == firstBaby.id }?.isActive == true)
    #expect(babies.filter { $0.isActive }.count == 1)
    #expect(repo.activeBaby?.id == firstBaby.id)
    #expect(state.headerConfig.babyID == firstBaby.id)
  }

  @Test("fetchAccessibleBabies separates owned and shared babies for family members")
  func fetchAccessibleBabiesSeparatesOwnedAndSharedForMembers() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    let memberID = UUID()
    let ownerID = UUID()
    #expect(repo.createDefaultIfNeeded() == true)
    let ownedBaby = try #require(repo.activeBaby)
    let sharedBaby = BabyProfile(
      name: "Shared",
      birthDate: env.now.value,
      createdAt: env.now.value.addingTimeInterval(60),
      isActive: false
    )
    env.modelContext.insert(sharedBaby)
    env.modelContext.insert(
      FamilyGroup(
        ownerUserID: ownerID,
        sharedBabyIDs: [sharedBaby.id],
        memberPayloads: [
          FamilyMemberSnapshot(
            userID: memberID, role: .member, joinedAt: env.now.value, removedAt: nil)
        ],
        createdAt: env.now.value,
        updatedAt: env.now.value
      )
    )
    try env.modelContext.save()

    let groups = try repo.fetchAccessibleBabies(for: memberID)

    #expect(groups.owned.map(\.id) == [ownedBaby.id])
    #expect(groups.shared.map(\.id) == [sharedBaby.id])
    #expect(
      try repo.access(for: sharedBaby.id, currentUserID: memberID)?.ownership
        == .shared(ownerUserID: ownerID))
  }

  @Test("createBabyResult counts only owned babies for entitlement when shared babies exist")
  func createBabyResultCountsOnlyOwnedBabiesForEntitlementWhenSharedBabiesExist() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository(canCreateAdditionalBaby: { $0 < 2 })
    let memberID = UUID()
    let ownerID = UUID()
    #expect(repo.createDefaultIfNeeded() == true)
    let sharedBaby = BabyProfile(
      name: "Shared",
      birthDate: env.now.value,
      createdAt: env.now.value.addingTimeInterval(60),
      isActive: false
    )
    env.modelContext.insert(sharedBaby)
    env.modelContext.insert(
      FamilyGroup(
        ownerUserID: ownerID,
        sharedBabyIDs: [sharedBaby.id],
        memberPayloads: [
          FamilyMemberSnapshot(
            userID: memberID, role: .member, joinedAt: env.now.value, removedAt: nil)
        ],
        createdAt: env.now.value,
        updatedAt: env.now.value
      )
    )
    try env.modelContext.save()

    let result = repo.createBabyResult(
      name: "Second Owned",
      birthDate: env.now.value,
      currentUserID: memberID
    )

    let createdBaby: BabyProfile
    switch result {
    case .success(let baby):
      createdBaby = baby
    case .failure(let failure):
      Issue.record("Expected createBabyResult to succeed, got failure: \(failure)")
      return
    }

    let groups = try repo.fetchAccessibleBabies(for: memberID)
    #expect(createdBaby.name == "Second Owned")
    #expect(groups.owned.count == 2)
    #expect(groups.shared.map(\.id) == [sharedBaby.id])
  }

  @Test("activateAccessibleBaby selects shared baby without changing persisted owned active baby")
  func activateAccessibleBabySelectsSharedBabyWithoutChangingPersistedActiveBaby() async throws {
    let env = try makeTestEnvironment(now: .now)
    let state = ActiveBabyState()
    let repo = env.makeBabyRepository(activeBabyState: state)
    let memberID = UUID()
    let ownerID = UUID()
    #expect(repo.createDefaultIfNeeded() == true)
    let ownedBaby = try #require(repo.activeBaby)
    let sharedBaby = BabyProfile(
      name: "Shared",
      birthDate: env.now.value,
      createdAt: env.now.value.addingTimeInterval(60),
      isActive: false
    )
    env.modelContext.insert(sharedBaby)
    env.modelContext.insert(
      FamilyGroup(
        ownerUserID: ownerID,
        sharedBabyIDs: [sharedBaby.id],
        memberPayloads: [
          FamilyMemberSnapshot(
            userID: memberID, role: .member, joinedAt: env.now.value, removedAt: nil)
        ],
        createdAt: env.now.value,
        updatedAt: env.now.value
      )
    )
    try env.modelContext.save()

    #expect(repo.activateAccessibleBaby(id: sharedBaby.id, currentUserID: memberID) == true)

    let babies = try repo.fetchBabies()
    #expect(babies.first { $0.id == ownedBaby.id }?.isActive == true)
    #expect(babies.first { $0.id == sharedBaby.id }?.isActive == false)
    #expect(state.headerConfig.babyID == sharedBaby.id)
    #expect(state.activeBabyAccess?.ownership == .shared(ownerUserID: ownerID))
  }

  @Test("fetchAccessibleBabies hides foreign baby after member removal")
  func fetchAccessibleBabiesHidesForeignBabyAfterMemberRemoval() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    let memberID = UUID()
    let ownerID = UUID()
    let ownedBaby = BabyProfile(
      ownerUserID: memberID,
      name: "Owned",
      birthDate: env.now.value,
      isActive: true
    )
    let sharedBaby = BabyProfile(
      ownerUserID: ownerID,
      name: "Shared",
      birthDate: env.now.value,
      createdAt: env.now.value.addingTimeInterval(60),
      isActive: false
    )
    env.modelContext.insert(ownedBaby)
    env.modelContext.insert(sharedBaby)
    env.modelContext.insert(
      FamilyGroup(
        ownerUserID: ownerID,
        sharedBabyIDs: [sharedBaby.id],
        memberPayloads: [
          FamilyMemberSnapshot(
            userID: memberID,
            role: .member,
            joinedAt: env.now.value,
            removedAt: env.now.value.addingTimeInterval(30)
          )
        ],
        createdAt: env.now.value,
        updatedAt: env.now.value
      )
    )
    try env.modelContext.save()

    let groups = try repo.fetchAccessibleBabies(for: memberID)

    #expect(groups.owned.map(\.id) == [ownedBaby.id])
    #expect(groups.shared.isEmpty)
    #expect(try repo.access(for: sharedBaby.id, currentUserID: memberID) == nil)
    #expect(repo.activateAccessibleBaby(id: sharedBaby.id, currentUserID: memberID) == false)
  }

  @Test("fetchAccessibleBabies hides local foreign baby once it is no longer shared")
  func fetchAccessibleBabiesHidesUnsharedForeignBaby() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()
    let memberID = UUID()
    let ownerID = UUID()
    let ownedBaby = BabyProfile(
      ownerUserID: memberID,
      name: "Owned",
      birthDate: env.now.value,
      isActive: true
    )
    let staleSharedBaby = BabyProfile(
      ownerUserID: ownerID,
      name: "Former Shared",
      birthDate: env.now.value,
      createdAt: env.now.value.addingTimeInterval(60),
      isActive: false
    )
    env.modelContext.insert(ownedBaby)
    env.modelContext.insert(staleSharedBaby)
    env.modelContext.insert(
      FamilyGroup(
        ownerUserID: ownerID,
        sharedBabyIDs: [],
        memberPayloads: [
          FamilyMemberSnapshot(
            userID: memberID, role: .member, joinedAt: env.now.value, removedAt: nil)
        ],
        createdAt: env.now.value,
        updatedAt: env.now.value
      )
    )
    try env.modelContext.save()

    let groups = try repo.fetchAccessibleBabies(for: memberID)

    #expect(groups.owned.map(\.id) == [ownedBaby.id])
    #expect(groups.shared.isEmpty)
    #expect(try repo.access(for: staleSharedBaby.id, currentUserID: memberID) == nil)
  }

  @Test("update methods fail safely when no active baby exists")
  func testUpdateMethodsFailWhenNoActiveBaby() async throws {
    let env = try makeTestEnvironment(now: .now)
    let repo = env.makeBabyRepository()

    #expect(repo.updateName("Noop") == false)
    #expect(repo.updateBirthDate(.now) == false)
    #expect(repo.updateGender(.female) == false)
    #expect(repo.markOnboardingCompleted() == false)
  }
}
