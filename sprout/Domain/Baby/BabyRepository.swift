import Foundation
import OSLog
import SwiftData

@MainActor
final class BabyRepository {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "sprout", category: "BabyRepository")
    weak var activeBabyState: ActiveBabyState?

    init(modelContext: ModelContext, activeBabyState: ActiveBabyState? = nil) {
        self.modelContext = modelContext
        self.activeBabyState = activeBabyState
    }

    var activeBaby: BabyProfile? {
        do {
            return try fetchActiveBaby()
        } catch {
            recordFailure(operation: "Fetch active baby", error: error)
            return nil
        }
    }

    @discardableResult
    func createDefaultIfNeeded() -> Bool {
        do {
            guard try fetchActiveBaby() == nil else { return true }
            let baby = BabyProfile()
            modelContext.insert(baby)
            try modelContext.save()
            return true
        } catch {
            recordFailure(operation: "Create default baby", error: error)
            return false
        }
    }

    @discardableResult
    func updateName(_ name: String) -> Bool {
        do {
            guard let baby = try fetchActiveBaby() else {
                recordFailure(operation: "Update baby name", reason: "No active baby found")
                return false
            }
            baby.name = name
            try modelContext.save()
            activeBabyState?.updateFrom(baby)
            return true
        } catch {
            recordFailure(operation: "Update baby name", error: error)
            return false
        }
    }

    @discardableResult
    func updateBirthDate(_ date: Date) -> Bool {
        do {
            guard let baby = try fetchActiveBaby() else {
                recordFailure(operation: "Update baby birth date", reason: "No active baby found")
                return false
            }
            baby.birthDate = date
            try modelContext.save()
            activeBabyState?.updateFrom(baby)
            return true
        } catch {
            recordFailure(operation: "Update baby birth date", error: error)
            return false
        }
    }

    @discardableResult
    func updateGender(_ gender: BabyProfile.Gender?) -> Bool {
        do {
            guard let baby = try fetchActiveBaby() else {
                recordFailure(operation: "Update baby gender", reason: "No active baby found")
                return false
            }
            baby.gender = gender
            try modelContext.save()
            activeBabyState?.updateFrom(baby)
            return true
        } catch {
            recordFailure(operation: "Update baby gender", error: error)
            return false
        }
    }

    @discardableResult
    func markOnboardingCompleted() -> Bool {
        do {
            guard let baby = try fetchActiveBaby() else {
                recordFailure(operation: "Mark onboarding completed", reason: "No active baby found")
                return false
            }
            baby.hasCompletedOnboarding = true
            try modelContext.save()
            return true
        } catch {
            recordFailure(operation: "Mark onboarding completed", error: error)
            return false
        }
    }

    private func fetchActiveBaby() throws -> BabyProfile? {
        var descriptor = FetchDescriptor<BabyProfile>(
            predicate: #Predicate<BabyProfile> { $0.isActive == true }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func recordFailure(operation: String, error: Error) {
        logger.error("\(operation, privacy: .public) failed: \(String(describing: error), privacy: .public)")
    }

    private func recordFailure(operation: String, reason: String) {
        logger.error("\(operation, privacy: .public) failed: \(reason, privacy: .public)")
    }
}
