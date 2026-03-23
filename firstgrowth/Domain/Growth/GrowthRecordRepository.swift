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
        let descriptor = FetchDescriptor<RecordItem>(
            predicate: #Predicate<RecordItem> { item in
                item.type == rawType
            },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        return try modelContext.fetch(descriptor)
    }

    func fetchLatestRecord(for metric: GrowthMetric) throws -> RecordItem? {
        let rawType = metric.recordType.rawValue
        var descriptor = FetchDescriptor<RecordItem>(
            predicate: #Predicate<RecordItem> { item in
                item.type == rawType
            },
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
}
