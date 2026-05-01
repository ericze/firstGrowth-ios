import Foundation

enum FamilyPermission {
    static func canEdit(
        authoredBy authorID: UUID?,
        currentUserID: UUID?,
        access: FamilyBabyAccess
    ) -> Bool {
        switch access.ownership {
        case .owned:
            return true
        case .shared:
            guard let authorID, let currentUserID else { return false }
            return authorID == currentUserID
        }
    }

    static func canEditContent(
        ownership: BabyOwnership,
        authoredByUserID: UUID?,
        currentUserID: UUID?
    ) -> Bool {
        switch ownership {
        case .owned:
            return true
        case .shared:
            guard let authoredByUserID, let currentUserID else { return false }
            return authoredByUserID == currentUserID
        }
    }
}
