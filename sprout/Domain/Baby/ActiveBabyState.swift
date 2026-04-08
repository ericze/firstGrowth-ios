import Foundation
import Observation

@MainActor
@Observable
final class ActiveBabyState {
    var headerConfig: HomeHeaderConfig

    init(headerConfig: HomeHeaderConfig? = nil) {
        self.headerConfig = headerConfig ?? .placeholder
    }

    func updateFrom(_ baby: BabyProfile?) {
        headerConfig = HomeHeaderConfig.from(baby)
    }
}
