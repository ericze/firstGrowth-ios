import Foundation
import SwiftData
import Testing
@testable import sprout

struct FamilyPermissionTests {
    @Test("shared-baby content is editable only by its author")
    func sharedBabyContentEditableOnlyByAuthor() {
        let authorID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let otherUserID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let ownerUserID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        #expect(
            FamilyPermission.canEditContent(
                ownership: .shared(ownerUserID: ownerUserID),
                authoredByUserID: authorID,
                currentUserID: authorID
            )
        )
        #expect(
            !FamilyPermission.canEditContent(
                ownership: .shared(ownerUserID: ownerUserID),
                authoredByUserID: authorID,
                currentUserID: otherUserID
            )
        )
        #expect(
            !FamilyPermission.canEditContent(
                ownership: .shared(ownerUserID: ownerUserID),
                authoredByUserID: nil,
                currentUserID: authorID
            )
        )
        #expect(
            !FamilyPermission.canEditContent(
                ownership: .shared(ownerUserID: ownerUserID),
                authoredByUserID: authorID,
                currentUserID: nil
            )
        )
    }

    @Test("schema v5 exposes version 5.0.0")
    func schemaV5VersionIdentifier() {
        #expect(SproutSchemaV5.versionIdentifier == Schema.Version(5, 0, 0))
    }
}
