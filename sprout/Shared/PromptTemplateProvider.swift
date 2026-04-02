import Foundation

struct PromptTemplateProvider {
    let language: AppLanguage

    init(locale: Locale = .autoupdatingCurrent) {
        self.language = AppLanguage(locale: locale)
    }

    var growthNarrationGuardrails: [String] {
        switch language {
        case .english:
            return [
                "Describe changes only, without rating quality.",
                "Avoid medical, nutrition, diagnostic, or peer-comparison claims.",
                "Prefer description over judgment."
            ]
        case .simplifiedChinese:
            return [
                "只描述变化，不评价质量。",
                "不要给出医疗、营养、诊断或同龄比较结论。",
                "文案优先描述，不做判断。"
            ]
        }
    }

    var weeklyLetterGuardrails: [String] {
        switch language {
        case .english:
            return [
                "Keep the tone calm and restrained.",
                "Do not turn memories into achievements, scores, or milestones with judgment.",
                "Avoid medical, nutrition, diagnostic, or peer-comparison language."
            ]
        case .simplifiedChinese:
            return [
                "保持安静、克制的语气。",
                "不要把记忆写成成就、打卡、评分或优劣判断。",
                "避免医疗、营养、诊断或同龄比较表达。"
            ]
        }
    }
}
