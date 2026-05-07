import XCTest
@testable import sprout

final class PaywallContentTests: XCTestCase {
    func test_policyLinks_areNotExampleDotCom() {
        XCTAssertNotEqual(PaywallContent.termsURL.host(), "example.com")
        XCTAssertNotEqual(PaywallContent.privacyURL.host(), "example.com")
    }

    func test_policyLinks_pointToProjectLegalDocs() {
        XCTAssertEqual(PaywallContent.termsURL.scheme, "https")
        XCTAssertEqual(PaywallContent.privacyURL.scheme, "https")
        XCTAssertTrue(PaywallContent.termsURL.path.contains("terms-of-service"))
        XCTAssertTrue(PaywallContent.privacyURL.path.contains("privacy-policy"))
    }

    func test_unreleasedCapabilities_areNotSoldAsPrimaryPaywallPromises() {
        let unreleasedCapabilities: Set<ProCapability> = [
            .multiBaby,
            .familyGroup,
            .cloudSync,
            .aiAssistant,
        ]

        XCTAssertTrue(PaywallContent.promotedCapabilities.isDisjoint(with: unreleasedCapabilities))
        XCTAssertFalse(PaywallContent.isPurchaseEnabled)
    }

    func test_releaseBlockedCapabilities_includeUnacceptedRemoteAndAIPromises() {
        let blockedUntilAcceptance: Set<ProCapability> = [
            .familyGroup,
            .cloudSync,
            .aiAssistant,
        ]

        XCTAssertTrue(PaywallContent.releaseBlockedCapabilities.isSuperset(of: blockedUntilAcceptance))
        XCTAssertTrue(PaywallContent.promotedCapabilities.isDisjoint(with: PaywallContent.releaseBlockedCapabilities))
    }

    func test_closedSaleSubtitle_doesNotPromiseImmediateUnlock() {
        XCTAssertFalse(PaywallContent.isPurchaseEnabled)
        XCTAssertFalse(PaywallContent.heroSubtitleEN.localizedCaseInsensitiveContains("unlock"))
        XCTAssertFalse(PaywallContent.heroSubtitleZH.contains("解锁"))
    }

    func test_aiFeatureCopy_staysInSuggestionScope() throws {
        let aiFeature = try XCTUnwrap(PaywallContent.allFeatures.first { $0.capability == .aiAssistant })

        XCTAssertFalse(aiFeature.titleEN.localizedCaseInsensitiveContains("assistant"))
        XCTAssertFalse(aiFeature.titleZH.contains("助手"))
        XCTAssertFalse(aiFeature.detailEN.localizedCaseInsensitiveContains("analysis"))
        XCTAssertFalse(aiFeature.detailEN.localizedCaseInsensitiveContains("report"))
        XCTAssertFalse(aiFeature.detailZH.contains("分析"))
        XCTAssertFalse(aiFeature.detailZH.contains("周报"))
    }
}
