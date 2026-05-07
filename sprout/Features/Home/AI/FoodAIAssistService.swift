import Foundation

/// Produces optional draft suggestions for a food record.
///
/// Suggestions are assistive only and must never block the manual logging flow.
protocol FoodAIAssistService: Sendable {
    func suggest(
        imageLocalPath: String,
        locale: Locale,
        allowedTags: [String],
        knownFoodTags: [String]
    ) async throws -> FoodAISuggestionResult
}
