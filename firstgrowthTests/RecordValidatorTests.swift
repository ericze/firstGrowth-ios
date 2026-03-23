import XCTest
@testable import firstgrowth

final class RecordValidatorTests: XCTestCase {
    private let validator = RecordValidator()

    func testMilkValidationAcceptsPositiveAmount() throws {
        XCTAssertNoThrow(
            try validator.validate(
                type: .milk,
                value: 120,
                subType: nil,
                tags: nil,
                note: nil,
                imageURL: nil
            )
        )
    }

    func testHeightValidationAcceptsPositiveValue() throws {
        XCTAssertNoThrow(
            try validator.validate(
                type: .height,
                value: 75.2,
                subType: nil,
                tags: nil,
                note: nil,
                imageURL: nil
            )
        )
    }

    func testDiaperValidationRejectsUnknownSubtype() {
        XCTAssertThrowsError(
            try validator.validate(
                type: .diaper,
                value: nil,
                subType: "wet",
                tags: nil,
                note: nil,
                imageURL: nil
            )
        ) { error in
            XCTAssertEqual(error as? RecordValidationError, .invalidDiaperSubtype("wet"))
        }
    }

    func testFoodValidationRejectsEmptyRecord() {
        XCTAssertThrowsError(
            try validator.validate(
                type: .food,
                value: nil,
                subType: nil,
                tags: nil,
                note: nil,
                imageURL: nil
            )
        ) { error in
            XCTAssertEqual(error as? RecordValidationError, .emptyFood)
        }
    }
}
