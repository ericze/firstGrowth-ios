import Foundation
@testable import sprout

final class MockSubscriptionCache: SubscriptionCache {
    var cachedProductID: String?
    var cachedExpiration: Date?
    var cachedIsActive: Bool = false

    func clear() {
        cachedProductID = nil
        cachedExpiration = nil
        cachedIsActive = false
    }
}
