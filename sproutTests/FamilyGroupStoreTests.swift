import Foundation
import SwiftData
import Testing
@testable import sprout

@MainActor
struct FamilyGroupStoreTests {
    @Test("pro owner can create a family group and rotate invite code")
    func proOwnerCanCreateFamilyGroupAndRotateInviteCode() async throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_711_500_000))
        let ownerID = UUID()
        let authManager = makeAuthenticatedAuthManager(userID: ownerID, email: "owner@example.com")
        let subscriptionManager = makeProSubscriptionManager(now: environment.now.value)

        var inviteCodes = ["SPROUT42", "SPROUT84"]
        let store = makeFamilyGroupStore(
            environment: environment,
            authManager: authManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value },
            inviteCodeGenerator: {
                inviteCodes.removeFirst()
            }
        )

        #expect(store.createFamilyGroup() == true)

        let createdFamily = try #require(store.currentFamilyGroup)
        #expect(createdFamily.ownerUserID == ownerID)
        #expect(createdFamily.inviteCode == "SPROUT42")
        #expect(store.ownershipState == .owner)
        #expect(store.error == nil)

        #expect(store.rotateInviteCode() == true)

        let rotatedFamily = try #require(store.currentFamilyGroup)
        #expect(rotatedFamily.id == createdFamily.id)
        #expect(rotatedFamily.inviteCode == "SPROUT84")
        #expect(rotatedFamily.inviteState == .active)
        #expect(rotatedFamily.ownerUserID == ownerID)

        let families = try environment.modelContext.fetch(FetchDescriptor<FamilyGroup>())
        #expect(families.count == 1)
        #expect(families.first?.inviteCode == "SPROUT84")
        #expect(families.first?.memberPayloads.first?.userID == ownerID)
        #expect(families.first?.memberPayloads.first?.role == .owner)
    }

    @Test("member can join a family group with a valid invite code")
    func memberCanJoinWithValidInviteCode() async throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_711_500_000))
        let ownerID = UUID()
        let memberID = UUID()
        let ownerAuthManager = makeAuthenticatedAuthManager(userID: ownerID, email: "owner@example.com")
        let memberAuthManager = makeAuthenticatedAuthManager(userID: memberID, email: "member@example.com")
        let subscriptionManager = makeProSubscriptionManager(now: environment.now.value)

        let ownerStore = makeFamilyGroupStore(
            environment: environment,
            authManager: ownerAuthManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value },
            inviteCodeGenerator: { "SPROUT42" }
        )
        #expect(ownerStore.createFamilyGroup() == true)

        let memberStore = makeFamilyGroupStore(
            environment: environment,
            authManager: memberAuthManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value }
        )

        #expect(memberStore.joinFamilyGroup(inviteCode: " sprout42 ") == true)

        let joinedFamily = try #require(memberStore.currentFamilyGroup)
        #expect(joinedFamily.ownerUserID == ownerID)
        #expect(memberStore.ownershipState == .member)
        #expect(memberStore.error == nil)
        #expect(joinedFamily.memberPayloads.contains { $0.userID == memberID && $0.role == .member && $0.removedAt == nil })

        #expect(ownerStore.loadCurrentFamilyGroup() == true)
        let refreshedOwnerFamily = try #require(ownerStore.currentFamilyGroup)
        #expect(refreshedOwnerFamily.memberPayloads.contains { $0.userID == memberID && $0.removedAt == nil })
    }

    @Test("member join fails for invalid expired and revoked invite codes")
    func memberJoinFailsForInvalidExpiredAndRevokedInviteCodes() async throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_711_500_000))
        let ownerID = UUID()
        let memberID = UUID()
        let ownerAuthManager = makeAuthenticatedAuthManager(userID: ownerID, email: "owner@example.com")
        let memberAuthManager = makeAuthenticatedAuthManager(userID: memberID, email: "member@example.com")
        let subscriptionManager = makeProSubscriptionManager(now: environment.now.value)

        let ownerStore = makeFamilyGroupStore(
            environment: environment,
            authManager: ownerAuthManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value },
            inviteCodeGenerator: { "SPROUT42" }
        )
        #expect(ownerStore.createFamilyGroup() == true)

        let memberStore = makeFamilyGroupStore(
            environment: environment,
            authManager: memberAuthManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value }
        )

        #expect(memberStore.joinFamilyGroup(inviteCode: "NOPE1234") == false)
        #expect(memberStore.error == .invalidInviteCode)

        guard let family = ownerStore.currentFamilyGroup else {
            Issue.record("Expected family group to exist after creation")
            return
        }

        family.inviteExpiresAt = environment.now.value.addingTimeInterval(-60)
        family.inviteState = .active
        try environment.modelContext.save()

        #expect(memberStore.joinFamilyGroup(inviteCode: "SPROUT42") == false)
        #expect(memberStore.error == .inviteExpired)

        family.inviteExpiresAt = nil
        family.inviteState = .revoked
        try environment.modelContext.save()

        #expect(memberStore.joinFamilyGroup(inviteCode: "SPROUT42") == false)
        #expect(memberStore.error == .inviteRevoked)
    }

    @Test("owner can share and unshare a baby")
    func ownerCanShareAndUnshareBaby() async throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_711_500_000))
        let ownerID = UUID()
        let ownerAuthManager = makeAuthenticatedAuthManager(userID: ownerID, email: "owner@example.com")
        let subscriptionManager = makeProSubscriptionManager(now: environment.now.value)
        let baby = BabyProfile(name: "小禾", birthDate: environment.now.value.addingTimeInterval(-86_400))
        environment.modelContext.insert(baby)
        try environment.modelContext.save()

        let ownerStore = makeFamilyGroupStore(
            environment: environment,
            authManager: ownerAuthManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value },
            inviteCodeGenerator: { "SPROUT42" }
        )
        #expect(ownerStore.createFamilyGroup() == true)

        #expect(ownerStore.setBabyShared(babyID: baby.id, shared: true) == true)
        #expect(ownerStore.currentFamilyGroup?.sharedBabyIDs == [baby.id])

        let sharedFamily = try #require(environment.modelContext.fetch(FetchDescriptor<FamilyGroup>()).first)
        #expect(sharedFamily.sharedBabyIDs == [baby.id])

        #expect(ownerStore.setBabyShared(babyID: baby.id, shared: false) == true)
        #expect(ownerStore.currentFamilyGroup?.sharedBabyIDs.isEmpty == true)
        #expect(sharedFamily.sharedBabyIDs.isEmpty == true)
    }

    @Test("owner can remove a member and the member no longer sees the family group")
    func ownerCanRemoveMemberAndMemberLosesVisibility() async throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_711_500_000))
        let ownerID = UUID()
        let memberID = UUID()
        let ownerAuthManager = makeAuthenticatedAuthManager(userID: ownerID, email: "owner@example.com")
        let memberAuthManager = makeAuthenticatedAuthManager(userID: memberID, email: "member@example.com")
        let subscriptionManager = makeProSubscriptionManager(now: environment.now.value)
        let baby = BabyProfile(name: "小果", birthDate: environment.now.value.addingTimeInterval(-86_400))
        environment.modelContext.insert(baby)
        try environment.modelContext.save()

        let ownerStore = makeFamilyGroupStore(
            environment: environment,
            authManager: ownerAuthManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value },
            inviteCodeGenerator: { "SPROUT42" }
        )
        #expect(ownerStore.createFamilyGroup() == true)
        #expect(ownerStore.setBabyShared(babyID: baby.id, shared: true) == true)

        let memberStore = makeFamilyGroupStore(
            environment: environment,
            authManager: memberAuthManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value }
        )
        #expect(memberStore.joinFamilyGroup(inviteCode: "SPROUT42") == true)
        #expect(memberStore.currentFamilyGroup != nil)
        #expect(memberStore.ownershipState == .member)

        #expect(ownerStore.removeMember(userID: memberID) == true)

        let refreshedOwnerFamily = try #require(ownerStore.currentFamilyGroup)
        #expect(refreshedOwnerFamily.memberPayloads.contains { $0.userID == memberID && $0.removedAt != nil })

        #expect(memberStore.loadCurrentFamilyGroup() == true)
        #expect(memberStore.currentFamilyGroup == nil)
        #expect(memberStore.ownershipState == .none)
        #expect(memberStore.error == nil)
    }

    @Test("member cannot rotate invite manage shared babies or remove members")
    func memberCannotManageOwnerOnlyFamilyGroupActions() async throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_711_500_000))
        let ownerID = UUID()
        let memberID = UUID()
        let ownerAuthManager = makeAuthenticatedAuthManager(userID: ownerID, email: "owner@example.com")
        let memberAuthManager = makeAuthenticatedAuthManager(userID: memberID, email: "member@example.com")
        let subscriptionManager = makeProSubscriptionManager(now: environment.now.value)
        let baby = BabyProfile(name: "小河", birthDate: environment.now.value.addingTimeInterval(-86_400))
        environment.modelContext.insert(baby)
        try environment.modelContext.save()

        let ownerStore = makeFamilyGroupStore(
            environment: environment,
            authManager: ownerAuthManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value },
            inviteCodeGenerator: { "SPROUT42" }
        )
        #expect(ownerStore.createFamilyGroup() == true)

        let memberStore = makeFamilyGroupStore(
            environment: environment,
            authManager: memberAuthManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value }
        )
        #expect(memberStore.joinFamilyGroup(inviteCode: "SPROUT42") == true)

        #expect(memberStore.rotateInviteCode() == false)
        #expect(memberStore.error == .notOwner)

        #expect(memberStore.setBabyShared(babyID: baby.id, shared: true) == false)
        #expect(memberStore.error == .notOwner)

        #expect(memberStore.removeMember(userID: ownerID) == false)
        #expect(memberStore.error == .notOwner)
    }

    @Test("free user cannot create a family group")
    func freeUserCannotCreateFamilyGroup() async throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_711_500_000))
        let userID = UUID()
        let authManager = makeAuthenticatedAuthManager(userID: userID, email: "free@example.com")
        let subscriptionManager = makeFreeSubscriptionManager()

        let store = makeFamilyGroupStore(
            environment: environment,
            authManager: authManager,
            subscriptionManager: subscriptionManager,
            nowProvider: { environment.now.value },
            inviteCodeGenerator: { "SPROUT42" }
        )

        #expect(store.createFamilyGroup() == false)
        #expect(store.currentFamilyGroup == nil)
        #expect(store.ownershipState == .none)
        #expect(store.error == .proRequired)

        let families = try environment.modelContext.fetch(FetchDescriptor<FamilyGroup>())
        #expect(families.isEmpty)
    }

    private func makeAuthenticatedAuthManager(userID: UUID, email: String) -> AuthManager {
        let manager = AuthManager(
            supabaseService: MockSupabaseService(),
            defaults: makeIsolatedDefaults(),
            linkedUserIDStorageKey: "family-group-tests.auth.linked.id"
        )
        manager.currentUser = SupabaseAuthUser(id: userID, email: email)
        manager.authState = .authenticated(userID: userID)
        return manager
    }

    private func makeProSubscriptionManager(now: Date) -> SubscriptionManager {
        let manager = SubscriptionManager(
            provider: MockProductProvider(),
            cache: MockSubscriptionCache(),
            nowProvider: { now }
        )
        manager.subscriptionStatus = .subscribed(
            productID: ProductID.monthly,
            expiration: now.addingTimeInterval(86_400)
        )
        return manager
    }

    private func makeFreeSubscriptionManager() -> SubscriptionManager {
        let manager = SubscriptionManager(
            provider: MockProductProvider(),
            cache: MockSubscriptionCache(),
            nowProvider: { Date(timeIntervalSince1970: 1_711_500_000) }
        )
        manager.subscriptionStatus = .notSubscribed
        return manager
    }

    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "family-group-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
