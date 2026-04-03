import Foundation

struct FoodTagCatalog {
    let language: AppLanguage

    init(language: AppLanguage) {
        self.language = language
    }

    var commonTags: [String] {
        switch language {
        case .english:
            [
                "Rice cereal",
                "Pumpkin",
                "Apple",
                "Banana",
                "Egg",
                "Avocado",
                "Noodles",
                "Tofu",
                "Carrot",
                "Potato",
                "Broccoli",
                "First taste"
            ]
        case .simplifiedChinese:
            [
                "米粉",
                "南瓜",
                "苹果",
                "香蕉",
                "鸡蛋",
                "牛油果",
                "面条",
                "豆腐",
                "胡萝卜",
                "土豆",
                "西兰花",
                "第一次尝试"
            ]
        }
    }

    /// Tags that should be searchable/selectable, including aliases.
    var allKnownTags: [String] {
        uniqueTags(from: commonTags + aliasMappings.keys)
    }

    /// Canonicalizes user-provided food tags to a stable tag vocabulary.
    /// Returns a trimmed display string when no alias match is found.
    func canonicalTag(for rawTag: String) -> String {
        let cleanedTag = rawTag.trimmed
        guard !cleanedTag.isEmpty else { return "" }

        let lookupKey = normalizedLookupKey(cleanedTag)
        if let canonical = canonicalByLookupKey[lookupKey] {
            return canonical
        }
        if let aliasMapped = aliasByLookupKey[lookupKey] {
            let canonicalLookupKey = normalizedLookupKey(aliasMapped)
            return canonicalByLookupKey[canonicalLookupKey] ?? aliasMapped
        }

        return cleanedTag
    }

    /// Compares whether two tags represent the same ingredient after canonicalization.
    func isEquivalentTag(_ lhs: String, _ rhs: String) -> Bool {
        let leftCanonical = canonicalTag(for: lhs)
        let rightCanonical = canonicalTag(for: rhs)
        guard !leftCanonical.isEmpty, !rightCanonical.isEmpty else {
            return false
        }
        return normalizedLookupKey(leftCanonical) == normalizedLookupKey(rightCanonical)
    }

    private var aliasMappings: [String: String] {
        switch language {
        case .english:
            [
                "Pumpkin puree": "Pumpkin",
                "Mashed pumpkin": "Pumpkin",
                "Apple puree": "Apple",
                "Mashed apple": "Apple",
                "Banana puree": "Banana",
                "Mashed banana": "Banana",
                "Avocado puree": "Avocado",
                "Mashed avocado": "Avocado",
                "Egg yolk": "Egg",
                "Carrot puree": "Carrot",
                "Potato puree": "Potato",
                "Broccoli puree": "Broccoli",
                "Rice porridge": "Rice cereal",
                "Rice puree": "Rice cereal",
            ]
        case .simplifiedChinese:
            [
                "米糊": "米粉",
                "米粉糊": "米粉",
                "南瓜泥": "南瓜",
                "苹果泥": "苹果",
                "香蕉泥": "香蕉",
                "蛋黄": "鸡蛋",
                "鸡蛋黄": "鸡蛋",
                "鸡蛋羹": "鸡蛋",
                "牛油果泥": "牛油果",
                "胡萝卜泥": "胡萝卜",
                "土豆泥": "土豆",
                "西兰花泥": "西兰花",
            ]
        }
    }

    private var canonicalByLookupKey: [String: String] {
        Dictionary(
            uniqueKeysWithValues: commonTags.map { (normalizedLookupKey($0), $0) }
        )
    }

    private var aliasByLookupKey: [String: String] {
        Dictionary(
            uniqueKeysWithValues: aliasMappings.map { (normalizedLookupKey($0.key), $0.value) }
        )
    }

    private func uniqueTags(from tags: [String]) -> [String] {
        var unique: [String] = []

        for tag in tags where !unique.contains(where: { isEquivalentTag($0, tag) }) {
            unique.append(canonicalTag(for: tag))
        }

        return unique
    }

    private func normalizedLookupKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .autoupdatingCurrent)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }
}
