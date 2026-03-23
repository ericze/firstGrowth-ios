import Foundation
import SwiftData

nonisolated final class TreasureRepository {
    private let modelContext: ModelContext
    private let calendar: Calendar

    @MainActor
    init(
        modelContext: ModelContext,
        calendar: Calendar = .current
    ) {
        self.modelContext = modelContext
        self.calendar = calendar
    }
}

@MainActor
extension TreasureRepository {
    func createMemoryEntry(
        note: String?,
        imageLocalPaths: [String],
        isMilestone: Bool,
        createdAt: Date,
        birthDate: Date
    ) throws -> MemoryEntry {
        let normalizedNote = note?.trimmed.nilIfEmpty
        let normalizedImagePaths = imageLocalPaths
            .compactMap { $0.trimmed.nilIfEmpty }
            .prefix(TreasureLimits.maxImagesPerEntry)
        let ageInDays = max(
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: birthDate),
                to: calendar.startOfDay(for: createdAt)
            ).day ?? 0,
            0
        )

        let entry = MemoryEntry(
            createdAt: createdAt,
            ageInDays: ageInDays,
            imageLocalPaths: Array(normalizedImagePaths),
            imageLocalPath: nil,
            note: normalizedNote,
            isMilestone: isMilestone
        )
        modelContext.insert(entry)
        try modelContext.save()
        return entry
    }

    func fetchMemoryEntries() throws -> [MemoryEntry] {
        let descriptor = FetchDescriptor<MemoryEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchWeeklyLetters() throws -> [WeeklyLetter] {
        let descriptor = FetchDescriptor<WeeklyLetter>(
            sortBy: [SortDescriptor(\.weekEnd, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchMemoryEntry(id: UUID) throws -> MemoryEntry? {
        var descriptor = FetchDescriptor<MemoryEntry>(
            predicate: #Predicate<MemoryEntry> { item in
                item.id == id
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func deleteMemoryEntry(id: UUID, removeImage: Bool = true) throws {
        var descriptor = FetchDescriptor<MemoryEntry>(
            predicate: #Predicate<MemoryEntry> { item in
                item.id == id
            }
        )
        descriptor.fetchLimit = 1

        guard let entry = try modelContext.fetch(descriptor).first else { return }
        if removeImage {
            TreasurePhotoStorage.removeImages(at: resolvedImageLocalPaths(for: entry))
        }
        modelContext.delete(entry)
        try modelContext.save()
    }

    func syncWeeklyLetter(
        for weekStart: Date,
        composer: WeeklyLetterComposer,
        generatedAt: Date
    ) throws {
        let normalizedWeekStart = calendar.startOfDay(for: weekStart)
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: normalizedWeekStart) ?? normalizedWeekStart

        let entries = try fetchEntries(in: normalizedWeekStart ... weekEnd.endOfDay(calendar: calendar))
        let existingLetter = try fetchWeeklyLetter(for: normalizedWeekStart)
        let newLetter = composer.compose(
            entries: entries,
            weekStart: normalizedWeekStart,
            weekEnd: weekEnd,
            generatedAt: generatedAt
        )

        switch (existingLetter, newLetter) {
        case let (existing?, replacement?):
            existing.weekEnd = replacement.weekEnd
            existing.density = replacement.density
            existing.collapsedText = replacement.collapsedText
            existing.expandedText = replacement.expandedText
            existing.generatedAt = replacement.generatedAt
            try modelContext.save()
        case (nil, let replacement?):
            modelContext.insert(replacement)
            try modelContext.save()
        case (let existing?, nil):
            modelContext.delete(existing)
            try modelContext.save()
        case (nil, nil):
            break
        }
    }

    private func fetchEntries(in range: ClosedRange<Date>) throws -> [MemoryEntry] {
        let descriptor = FetchDescriptor<MemoryEntry>(
            predicate: #Predicate<MemoryEntry> { item in
                item.createdAt >= range.lowerBound && item.createdAt <= range.upperBound
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchWeeklyLetter(for weekStart: Date) throws -> WeeklyLetter? {
        var descriptor = FetchDescriptor<WeeklyLetter>(
            predicate: #Predicate<WeeklyLetter> { item in
                item.weekStart == weekStart
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func resolvedImageLocalPaths(for entry: MemoryEntry) -> [String] {
        let normalizedPaths = entry.imageLocalPaths.compactMap { $0.trimmed.nilIfEmpty }
        if !normalizedPaths.isEmpty {
            return normalizedPaths
        }
        return [entry.imageLocalPath?.trimmed.nilIfEmpty].compactMap { $0 }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension Date {
    func endOfDay(calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: self)
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? self
    }
}
