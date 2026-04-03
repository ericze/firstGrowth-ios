import Foundation

enum OnboardingStep: Int, CaseIterable {
    case identity
    case permissions
}

struct OnboardingDraft {
    var name: String = ""
    var birthDate: Date = .now

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
}
