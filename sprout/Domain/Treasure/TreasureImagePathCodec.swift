import Foundation

enum TreasureImagePathCodec {
    private static let multiImagePrefix = "__treasure_paths__:"

    static func encodeStorageValue(for imageLocalPaths: [String]) -> String? {
        let normalizedPaths = normalize(imageLocalPaths)
        guard !normalizedPaths.isEmpty else { return nil }

        if normalizedPaths.count == 1 {
            return normalizedPaths[0]
        }

        guard
            let data = try? JSONEncoder().encode(normalizedPaths),
            let payload = String(data: data, encoding: .utf8)
        else {
            return normalizedPaths[0]
        }

        return multiImagePrefix + payload
    }

    static func decodeStorageValue(_ value: String?) -> [String] {
        guard let value = value?.trimmed.nilIfEmpty else { return [] }

        guard value.hasPrefix(multiImagePrefix) else {
            return [value]
        }

        let payload = String(value.dropFirst(multiImagePrefix.count))
        guard
            let data = payload.data(using: .utf8),
            let decodedPaths = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }

        return normalize(decodedPaths)
    }

    private static func normalize(_ paths: [String]) -> [String] {
        paths.compactMap { $0.trimmed.nilIfEmpty }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
