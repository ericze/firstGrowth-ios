import Foundation
import os
import UIKit

enum FoodPhotoStorageError: Error {
    case encodingFailed
}

enum FoodPhotoStorage {
    private static let logger = Logger(subsystem: "sprout", category: "FoodPhotoStorage")
    private static let pendingDeletionQueue = DispatchQueue(label: "sprout.food-photo.pending-deletion")

    static func storeImageData(_ data: Data) throws -> String {
        let fileURL = storageDirectoryURL.appendingPathComponent("food-\(UUID().uuidString).jpg")
        try ensureStorageDirectory()
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    static func storeImage(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.88) else {
            throw FoodPhotoStorageError.encodingFailed
        }
        return try storeImageData(data)
    }

    @discardableResult
    static func removeImage(at path: String?) -> Bool {
        guard let trimmedPath = path?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedPath.isEmpty else {
            return true
        }

        guard let fileURL = validatedFileURL(forPath: trimmedPath) else {
            logger.error("Rejected deleting photo outside FoodPhotos directory: \(trimmedPath, privacy: .public)")
            return false
        }

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            return true
        } catch {
            logger.error("Failed deleting food photo: \(fileURL.path, privacy: .public), error: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    static func hasImage(at path: String?) -> Bool {
        guard let normalizedPath = normalizedManagedPath(from: path) else {
            return false
        }

        return FileManager.default.fileExists(atPath: normalizedPath)
    }

    static func schedulePendingRemoval(for recordID: UUID, at path: String?, deleteAfter: Date) {
        guard let normalizedPath = normalizedManagedPath(from: path) else {
            return
        }

        pendingDeletionQueue.sync {
            var entries = loadPendingDeletions()
            entries.removeAll { $0.recordID == recordID || $0.path == normalizedPath }
            entries.append(
                PendingDeletionEntry(
                    recordID: recordID,
                    path: normalizedPath,
                    deleteAfter: deleteAfter
                )
            )
            savePendingDeletions(entries)
        }
    }

    static func cancelPendingRemoval(for recordID: UUID, path: String?) {
        let normalizedPath = normalizedManagedPath(from: path)

        pendingDeletionQueue.sync {
            let entries = loadPendingDeletions()
            let filteredEntries = entries.filter { entry in
                if entry.recordID == recordID {
                    return false
                }

                if let normalizedPath, entry.path == normalizedPath {
                    return false
                }

                return true
            }

            guard filteredEntries.count != entries.count else {
                return
            }

            savePendingDeletions(filteredEntries)
        }
    }

    static func flushExpiredPendingRemovals(now: Date) {
        let expiredPaths = pendingDeletionQueue.sync { () -> [String] in
            let entries = loadPendingDeletions()
            let activeEntries = entries.filter { $0.deleteAfter > now }

            if activeEntries.count != entries.count {
                savePendingDeletions(activeEntries)
            }

            return Array(Set(entries.filter { $0.deleteAfter <= now }.map(\.path)))
        }

        for path in expiredPaths where !removeImage(at: path) {
            logger.error("Pending photo cleanup failed for path: \(path, privacy: .public)")
        }
    }

    private static var storageDirectoryURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return root.appendingPathComponent("FoodPhotos", isDirectory: true)
    }

    private static var pendingDeletionManifestURL: URL {
        storageDirectoryURL.appendingPathComponent("pending-photo-deletions.json")
    }

    private static func ensureStorageDirectory() throws {
        try FileManager.default.createDirectory(
            at: storageDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    private static func normalizedManagedPath(from path: String?) -> String? {
        guard let trimmedPath = path?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedPath.isEmpty else {
            return nil
        }

        guard let fileURL = validatedFileURL(forPath: trimmedPath) else {
            logger.error("Rejected using photo outside FoodPhotos directory: \(trimmedPath, privacy: .public)")
            return nil
        }

        return fileURL.path
    }

    private static func validatedFileURL(forPath path: String) -> URL? {
        let candidateURL = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
        let rootURL = storageDirectoryURL.standardizedFileURL.resolvingSymlinksInPath()
        let rootPathPrefix = rootURL.path.hasSuffix("/") ? rootURL.path : "\(rootURL.path)/"
        guard candidateURL.path.hasPrefix(rootPathPrefix) else {
            return nil
        }
        return candidateURL
    }

    private static func loadPendingDeletions() -> [PendingDeletionEntry] {
        let fileURL = pendingDeletionManifestURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([PendingDeletionEntry].self, from: data)
        } catch {
            logger.error("Failed loading pending photo deletions: \(String(describing: error), privacy: .public)")
            return []
        }
    }

    private static func savePendingDeletions(_ entries: [PendingDeletionEntry]) {
        let fileURL = pendingDeletionManifestURL

        do {
            if entries.isEmpty {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
                return
            }

            try ensureStorageDirectory()
            let sortedEntries = entries.sorted { $0.deleteAfter < $1.deleteAfter }
            let data = try JSONEncoder().encode(sortedEntries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Failed saving pending photo deletions: \(String(describing: error), privacy: .public)")
        }
    }
}

private struct PendingDeletionEntry: Codable, Equatable {
    let recordID: UUID
    let path: String
    let deleteAfter: Date
}
