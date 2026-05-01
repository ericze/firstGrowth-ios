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
