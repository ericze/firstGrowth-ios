import Foundation

/// Local-only fallback that exercises the AI suggestion surface without network access.
final class MockFoodAIAssistService: FoodAIAssistService, @unchecked Sendable {
    var resultToReturn: FoodAISuggestionResult?
    var errorToThrow: Error?

    func suggest(
        imageLocalPath: String,
        locale: Locale,
        allowedTags: [String],
        knownFoodTags: [String]
    ) async throws -> FoodAISuggestionResult {
        if let error = errorToThrow { throw error }
        return resultToReturn ?? FoodAISuggestionResult(
            candidateTags: allowedTags.prefix(3).map { FoodTagCandidate(tag: $0, confidence: 0.45) },
            candidateAllergenGroups: [],
            textureStage: nil,
            noteSuggestion: nil,
            confidenceLevel: .low
        )
    }
}
