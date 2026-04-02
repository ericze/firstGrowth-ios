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
}
