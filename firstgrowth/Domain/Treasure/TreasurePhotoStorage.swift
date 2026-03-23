import Foundation
import UIKit

enum TreasurePhotoStorageError: Error {
    case encodingFailed
}

enum TreasurePhotoStorage {
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

    static func removeImage(at path: String?) {
        guard let path, !path.isEmpty else { return }
        try? FileManager.default.removeItem(atPath: path)
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
}
