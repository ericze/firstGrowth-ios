import CoreGraphics
import Foundation

enum GrowthMetric: String, Codable, CaseIterable, Identifiable {
    case height
    case weight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .height:
            "身高"
        case .weight:
            "体重"
        }
    }

    var unit: String {
        switch self {
        case .height:
            "cm"
        case .weight:
            "kg"
        }
    }

    var recordType: RecordType {
        switch self {
        case .height:
            .height
        case .weight:
            .weight
        }
    }

    var emptyText: String {
        switch self {
        case .height:
            "还没有身高记录"
        case .weight:
            "还没有体重记录"
        }
    }

    var entryTitle: String {
        switch self {
        case .height:
            "记录身高"
        case .weight:
            "记录体重"
        }
    }
}

enum GrowthChartInteractionState: Equatable {
    case idle
    case scrubbing
    case precisionVisible
    case precisionFading
}

enum GrowthAIState: Equatable {
    case expanded
    case collapsed
}

enum GrowthSheetState: Equatable {
    case closed
    case openHeight
    case openWeight
    case manualInputHeight
    case manualInputWeight

    var isPresented: Bool {
        self != .closed
    }

    var metric: GrowthMetric? {
        switch self {
        case .openHeight, .manualInputHeight:
            .height
        case .openWeight, .manualInputWeight:
            .weight
        case .closed:
            nil
        }
    }

    var isManualInput: Bool {
        self == .manualInputHeight || self == .manualInputWeight
    }
}

enum GrowthDataState: Equatable {
    case loading
    case empty
    case hasData
    case error
}

struct GrowthPoint: Identifiable, Equatable {
    let id: UUID
    let recordID: UUID
    let date: Date
    let ageInDays: Int
    let ageText: String
    let value: Double
}

struct GrowthMetaInfo: Equatable {
    let summaryText: String
}

struct GrowthTooltipData: Equatable {
    let ageText: String
    let valueText: String
}

struct GrowthAIContent: Equatable {
    let expandedText: String
    let collapsedText: String
}

struct GrowthReferenceBandPoint: Identifiable, Equatable {
    let ageInDays: Int
    let lower: Double
    let upper: Double

    var id: Int { ageInDays }
}

struct GrowthChartSelection: Equatable {
    let index: Int
    let point: GrowthPoint
    let tooltip: GrowthTooltipData
}

struct GrowthYAxisLabel: Identifiable, Equatable {
    let id: String
    let text: String
    let normalizedY: Double
}

struct GrowthRulerConfig: Equatable {
    let metric: GrowthMetric
    let range: ClosedRange<Double>
    let precision: Double
    let selectionStep: Double
    let strongStep: Double
    let unit: String

    static func `for`(_ metric: GrowthMetric, productConfig: GrowthProductConfig) -> GrowthRulerConfig {
        switch metric {
        case .height:
            return GrowthRulerConfig(
                metric: .height,
                range: productConfig.heightRange,
                precision: 0.1,
                selectionStep: 0.5,
                strongStep: 1.0,
                unit: metric.unit
            )
        case .weight:
            return GrowthRulerConfig(
                metric: .weight,
                range: productConfig.weightRange,
                precision: 0.1,
                selectionStep: 0.1,
                strongStep: 0.5,
                unit: metric.unit
            )
        }
    }
}

struct GrowthEntryDraftState: Equatable {
    var value: Double = 0
    var manualInput: String = ""
}

struct GrowthViewState: Equatable {
    var currentMetric: GrowthMetric = .height
    var chartInteractionState: GrowthChartInteractionState = .idle
    var aiState: GrowthAIState = .expanded
    var sheetState: GrowthSheetState = .closed
    var dataState: GrowthDataState = .loading
    var points: [GrowthPoint] = []
    var referenceBands: [GrowthReferenceBandPoint] = []
    var metaInfo = GrowthMetaInfo(summaryText: "")
    var aiContent = GrowthAIContent(expandedText: "", collapsedText: "")
    var selection: GrowthChartSelection?
    var yAxisLabels: [GrowthYAxisLabel] = []
    var entryDraft = GrowthEntryDraftState()
    var undoToast: UndoToastState?
    var hasLoadedInitialData = false
    var currentAgeInDays = 0
    var errorMessage: String?

    var isPrecisionVisible: Bool {
        chartInteractionState != .idle
    }
}

enum GrowthAction {
    case onAppear
    case selectMetric(GrowthMetric)
    case toggleAIState
    case tapEntry
    case dismissSheet
    case switchToManualInput
    case switchToRulerInput
    case updateManualInput(String)
    case updateRulerValue(Double)
    case saveRecord
    case undoLastRecord
    case dismissUndo
    case beginScrubbing(locationX: CGFloat, plotWidth: CGFloat)
    case updateScrubbing(locationX: CGFloat, plotWidth: CGFloat)
    case endScrubbing
}
