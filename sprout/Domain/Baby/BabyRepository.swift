import Foundation
import SwiftData

@MainActor
final class BabyRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var activeBaby: BabyProfile? {
        var descriptor = FetchDescriptor<BabyProfile>(
            predicate: #Predicate<BabyProfile> { $0.isActive == true }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func createDefaultIfNeeded() {
        guard activeBaby == nil else { return }
        let baby = BabyProfile()
        modelContext.insert(baby)
        try? modelContext.save()
    }

    func updateName(_ name: String) {
        guard let baby = activeBaby else { return }
        baby.name = name
        try? modelContext.save()
    }

    func updateBirthDate(_ date: Date) {
        guard let baby = activeBaby else { return }
        baby.birthDate = date
        try? modelContext.save()
    }

    func updateGender(_ gender: BabyProfile.Gender?) {
        guard let baby = activeBaby else { return }
        baby.gender = gender
        try? modelContext.save()
    }
}
