import Foundation

enum RecordType: String, Codable, CaseIterable {
    case milk
    case diaper
    case sleep
    case food
    case height
    case weight
}

enum DiaperSubtype: String, Codable, CaseIterable {
    case pee
    case poop
    case both

    var title: String {
        switch self {
        case .pee:
            "尿布：小便"
        case .poop:
            "尿布：大便"
        case .both:
            "尿布：都有"
        }
    }
}

enum TimelineCardStyle: Equatable {
    case standard
    case foodPhoto
}

enum RecordIcon: Equatable {
    case milk
    case diaper
    case sleep
    case food
    case height
    case weight

    var systemName: String {
        switch self {
        case .milk:
            "drop.fill"
        case .diaper:
            "circle.grid.2x2.fill"
        case .sleep:
            "moon.zzz.fill"
        case .food:
            "fork.knife.circle.fill"
        case .height:
            "ruler"
        case .weight:
            "scalemass"
        }
    }
}
