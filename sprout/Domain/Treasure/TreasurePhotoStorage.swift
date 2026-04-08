import Foundation
import os
import UIKit

enum TreasurePhotoStorageError: Error {
    case encodingFailed
}

enum TreasurePhotoStorage {
    private static let logger = Logger(subsystem: "sprout", category: "TreasurePhotoStorage")

    static func storeImageData(_ data: Data) throws -> String {
        let fileURL = storageDirectoryURL.appendingPathComponent("treasure-\(UUID().uuidString).jpg")
        try ensureStorageDirectory()
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    static func storeImage(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw TreasurePhotoStorageError.encodingFailed
        }
        return try storeImageData(data)
    }

    @discardableResult
    static func removeImage(at path: String?) -> Bool {
        guard let trimmedPath = path?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedPath.isEmpty else {
            return true
        }

        guard let fileURL = validatedFileURL(forPath: trimmedPath) else {
            logger.error("Rejected deleting photo outside TreasurePhotos directory: \(trimmedPath, privacy: .public)")
            return false
        }

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            return true
        } catch {
            logger.error("Failed deleting treasure photo: \(fileURL.path, privacy: .public), error: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    @discardableResult
    static func removeImages(at paths: [String]) -> [String] {
        paths.compactMap { removeImage(at: $0) ? nil : $0 }
    }

    private static var storageDirectoryURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return root.appendingPathComponent("TreasurePhotos", isDirectory: true)
    }

    private static func ensureStorageDirectory() throws {
        try FileManager.default.createDirectory(
            at: storageDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
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
}
