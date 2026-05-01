import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class FamilyGroupStore {
    enum OwnershipState: Equatable {
        case none
        case owner
        case member
    }

    enum Failure: Error, Equatable {
        case unauthenticated
        case proRequired
        case familyGroupAlreadyExists
        case familyGroupNotFound
        case notOwner
        case persistenceFailed

        @MainActor
        var userMessage: String {
            switch self {
            case .unauthenticated:
                return L10n.text(
                    "family_group.error.unauthenticated",
                    en: "Sign in to manage a family group.",
                    zh: "请先登录后再管理家庭组。"
                )
            case .proRequired:
                return L10n.text(
                    "family_group.error.pro_required",
                    en: "Family group is part of Pro.",
                    zh: "家庭组属于 Pro 功能。"
                )
            case .familyGroupAlreadyExists:
                return L10n.text(
                    "family_group.error.already_exists",
                    en: "A family group already exists for this account.",
                    zh: "这个账号已经有家庭组了。"
                )
            case .familyGroupNotFound:
                return L10n.text(
                    "family_group.error.not_found",
                    en: "No family group was found.",
                    zh: "没有找到家庭组。"
                )
            case .notOwner:
                return L10n.text(
                    "family_group.error.not_owner",
                    en: "Only the owner can change the invite code.",
                    zh: "只有创建者可以修改邀请码。"
                )
            case .persistenceFailed:
                return L10n.text(
                    "family_group.error.persistence_failed",
                    en: "Family group changes could not be saved.",
                    zh: "家庭组变更未能保存。"
                )
            }
        }
    }

    var currentFamilyGroup: FamilyGroup?
    var ownershipState: OwnershipState = .none
    var isLoading = false
    var error: Failure?

    @ObservationIgnored private let authManager: AuthManager
    @ObservationIgnored private let subscriptionManager: SubscriptionManager
    @ObservationIgnored private let repository: FamilyGroupRepository
    @ObservationIgnored private let logger = Logger(subsystem: "sprout", category: "FamilyGroupStore")

    init(
        authManager: AuthManager,
        subscriptionManager: SubscriptionManager,
        repository: FamilyGroupRepository
    ) {
        self.authManager = authManager
        self.subscriptionManager = subscriptionManager
        self.repository = repository
    }

    @discardableResult
    func loadCurrentFamilyGroup() -> Bool {
        isLoading = true
        defer { isLoading = false }

        guard let currentUserID = currentAuthenticatedUserID else {
            currentFamilyGroup = nil
            ownershipState = .none
            error = nil
            return false
        }

        do {
            let familyGroup = try repository.loadCurrentFamilyGroup(for: currentUserID)
            currentFamilyGroup = familyGroup
            ownershipState = Self.ownershipState(
                for: familyGroup,
                currentUserID: currentUserID
            )
            error = nil
            return true
        } catch {
            recordFailure(operation: "Load family group", error: error)
            currentFamilyGroup = nil
            ownershipState = .none
            self.error = .persistenceFailed
            return false
        }
    }

    @discardableResult
    func createFamilyGroup() -> Bool {
        guard let currentUserID = currentAuthenticatedUserID else {
            resetStateForFailure(.unauthenticated)
            return false
        }
        guard subscriptionManager.allows(.familyGroup) else {
            resetStateForFailure(.proRequired)
            return false
        }

        do {
            let familyGroup = try repository.createFamilyGroup(for: currentUserID)
            currentFamilyGroup = familyGroup
            ownershipState = .owner
            error = nil
            return true
        } catch let failure as FamilyGroupRepository.Failure {
            switch failure {
            case .familyGroupAlreadyExists:
                resetStateForFailure(.familyGroupAlreadyExists)
            case .persistenceFailed:
                resetStateForFailure(.persistenceFailed)
            case .familyGroupNotFound, .notOwner:
                resetStateForFailure(.persistenceFailed)
            }
            return false
        } catch {
            recordFailure(operation: "Create family group", error: error)
            resetStateForFailure(.persistenceFailed)
            return false
        }
    }

    @discardableResult
    func rotateInviteCode() -> Bool {
        guard let currentUserID = currentAuthenticatedUserID else {
            resetStateForFailure(.unauthenticated)
            return false
        }
        guard subscriptionManager.allows(.familyGroup) else {
            resetStateForFailure(.proRequired)
            return false
        }

        do {
            let familyGroup = try repository.rotateInviteCode(for: currentUserID)
            currentFamilyGroup = familyGroup
            ownershipState = .owner
            error = nil
            return true
        } catch let failure as FamilyGroupRepository.Failure {
            switch failure {
            case .familyGroupNotFound:
                resetStateForFailure(.familyGroupNotFound)
            case .notOwner:
                resetStateForFailure(.notOwner)
            case .familyGroupAlreadyExists, .persistenceFailed:
                resetStateForFailure(.persistenceFailed)
            }
            return false
        } catch {
            recordFailure(operation: "Rotate family invite code", error: error)
            resetStateForFailure(.persistenceFailed)
            return false
        }
    }

    var currentUserID: UUID? {
        currentAuthenticatedUserID
    }

    private var currentAuthenticatedUserID: UUID? {
        guard case .authenticated(let userID) = authManager.authState else {
            return nil
        }
        return authManager.currentUserID ?? userID
    }

    private func resetStateForFailure(_ failure: Failure) {
        error = failure
        logger.debug("Family group action failed: \(String(describing: failure), privacy: .public)")
    }

    private func recordFailure(operation: String, error: Error) {
        logger.error("\(operation, privacy: .public) failed: \(String(describing: error), privacy: .public)")
    }

    private static func ownershipState(
        for familyGroup: FamilyGroup?,
        currentUserID: UUID
    ) -> OwnershipState {
        guard let familyGroup else { return .none }
        if familyGroup.ownerUserID == currentUserID {
            return .owner
        }
        return familyGroup.memberPayloads.contains(where: { snapshot in
            snapshot.userID == currentUserID && snapshot.removedAt == nil
        }) ? .member : .none
    }
}
