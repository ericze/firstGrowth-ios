import Foundation
import SwiftData

nonisolated final class GrowthRecordRepository {
    private let modelContext: ModelContext
    private let validator: RecordValidator

    @MainActor
    init(
        modelContext: ModelContext,
        validator: RecordValidator = RecordValidator()
    ) {
        self.modelContext = modelContext
        self.validator = validator
    }
}

@MainActor
extension GrowthRecordRepository {
    func fetchRecords(for metric: GrowthMetric) throws -> [RecordItem] {
        let rawType = metric.recordType.rawValue
        let activeBabyID = resolvedActiveBabyID()
        let predicate: Predicate<RecordItem>
        if let activeBabyID {
            predicate = #Predicate<RecordItem> { item in
                item.babyID == activeBabyID && item.type == rawType
            }
        } else {
            predicate = #Predicate<RecordItem> { item in
                item.type == rawType
            }
        }
        let descriptor = FetchDescriptor<RecordItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchLatestRecord(for metric: GrowthMetric) throws -> RecordItem? {
        let rawType = metric.recordType.rawValue
        let activeBabyID = resolvedActiveBabyID()
        let predicate: Predicate<RecordItem>
        if let activeBabyID {
            predicate = #Predicate<RecordItem> { item in
                item.babyID == activeBabyID && item.type == rawType
            }
        } else {
            predicate = #Predicate<RecordItem> { item in
                item.type == rawType
            }
        }
        var descriptor = FetchDescriptor<RecordItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func createRecord(metric: GrowthMetric, value: Double, at date: Date) throws -> RecordItem {
        let record = RecordItem(
            timestamp: date,
            type: metric.recordType.rawValue,
            value: value
        )
        if let activeBabyID = resolvedActiveBabyID() {
            record.babyID = activeBabyID
        }
        try validator.validate(record)
        modelContext.insert(record)
        try modelContext.save()
        return record
    }

    func deleteRecord(id: UUID) throws {
        var descriptor = FetchDescriptor<RecordItem>(
            predicate: #Predicate<RecordItem> { item in
                item.id == id
            }
        )
        descriptor.fetchLimit = 1

        guard let record = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(record)
        try modelContext.save()
    }

    private func resolvedActiveBabyID() -> UUID? {
        var activeDescriptor = FetchDescriptor<BabyProfile>(
            predicate: #Predicate<BabyProfile> { profile in
                profile.isActive == true
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        activeDescriptor.fetchLimit = 1
        if let activeBaby = try? modelContext.fetch(activeDescriptor).first {
            return activeBaby.id
        }

        var fallbackDescriptor = FetchDescriptor<BabyProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        fallbackDescriptor.fetchLimit = 1
        return try? modelContext.fetch(fallbackDescriptor).first?.id
    }
}
