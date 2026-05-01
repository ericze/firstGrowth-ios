import Foundation
import Observation

@MainActor
@Observable
final class ActiveBabyState {
    var headerConfig: HomeHeaderConfig
    var activeBabyAccess: FamilyBabyAccess?

    init(headerConfig: HomeHeaderConfig? = nil) {
        let resolvedConfig = headerConfig ?? .placeholder
        self.headerConfig = resolvedConfig
        activeBabyAccess = FamilyBabyAccess(babyID: resolvedConfig.babyID, ownership: .owned)
    }

    func updateFrom(_ baby: BabyProfile?, access: FamilyBabyAccess? = nil) {
        headerConfig = HomeHeaderConfig.from(baby)
        if let access {
            activeBabyAccess = access
        } else if let baby {
            activeBabyAccess = FamilyBabyAccess(babyID: baby.id, ownership: .owned)
        } else {
            activeBabyAccess = nil
        }
    }
}
