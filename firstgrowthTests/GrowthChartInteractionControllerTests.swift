import XCTest
@testable import firstgrowth

@MainActor
final class GrowthChartInteractionControllerTests: XCTestCase {
    func testNearestIndexSnapsToClosestPoint() {
        let controller = GrowthChartInteractionController()

        XCTAssertEqual(controller.nearestIndex(locationX: 0, chartWidth: 300, itemCount: 4), 0)
        XCTAssertEqual(controller.nearestIndex(locationX: 150, chartWidth: 300, itemCount: 4), 2)
        XCTAssertEqual(controller.nearestIndex(locationX: 300, chartWidth: 300, itemCount: 4), 3)
    }

    func testScheduleFadeTransitionsAndCompletes() async {
        let controller = GrowthChartInteractionController(
            fadeDelayNanoseconds: 1,
            delayRunner: { _ in }
        )

        let expectation = expectation(description: "fade completed")
        var transitioned = false
        var completed = false

        controller.scheduleFade(
            onTransition: { transitioned = true },
            onCompletion: {
                completed = true
                expectation.fulfill()
            }
        )

        XCTAssertTrue(transitioned)
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertTrue(completed)
    }
}
