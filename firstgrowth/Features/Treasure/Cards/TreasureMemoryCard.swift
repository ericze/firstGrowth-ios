import SwiftUI
import UIKit

struct TreasureMemoryCard: View {
    let item: TreasureTimelineItem

    var body: some View {
        TreasureMemoryCardBody(
            item: item,
            background: AppTheme.Colors.cardBackground,
            accent: nil
        )
    }
}

struct TreasureMilestoneCard: View {
    let item: TreasureTimelineItem

    var body: some View {
        TreasureMemoryCardBody(
            item: item,
            background: AppTheme.Colors.highlight.opacity(0.12),
            accent: Image(systemName: "star.fill")
        )
    }
}

private struct TreasureMemoryCardBody: View {
    let item: TreasureTimelineItem
    let background: Color
    let accent: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                if let accent {
                    accent
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.highlight)
                }

                Text(metaText)
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            if let image = previewImage {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }

            if item.hasImageLoadError, item.note != nil {
                Text("这张照片暂时没有加载出来。")
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }

            if item.isMilestone {
                TreasureMilestoneText(note: item.note)
            } else if let note = item.note?.trimmed.nilIfEmpty {
                Text(note)
                    .font(AppTheme.Typography.cardBody)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private var previewImage: Image? {
        guard let path = item.imageLocalPath, let image = UIImage(contentsOfFile: path) else { return nil }
        return Image(uiImage: image)
    }

    private var metaText: String {
        let formatter = TreasureTimestampFormatter.shared
        return formatter.string(from: item.createdAt, ageInDays: item.ageInDays)
    }
}

private struct TreasureMilestoneText: View {
    let note: String?

    var body: some View {
        if let content = note?.trimmed.nilIfEmpty {
            let emphasis = emphasizedSegments(for: content)

            VStack(alignment: .leading, spacing: emphasis.trailingText == nil ? 0 : 10) {
                if let leadingText = emphasis.leadingText {
                    Text(leadingText)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let trailingText = emphasis.trailingText {
                    Text(trailingText)
                        .font(AppTheme.Typography.cardBody)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                } else if emphasis.leadingText == nil {
                    Text(content)
                        .font(AppTheme.Typography.cardBody)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func emphasizedSegments(for content: String) -> (leadingText: String?, trailingText: String?) {
        if let newlineRange = content.range(of: "\n") {
            let leading = String(content[..<newlineRange.lowerBound]).trimmed
            let trailing = String(content[newlineRange.upperBound...]).trimmed.nilIfEmpty
            return (leading.nilIfEmpty, trailing)
        }

        let punctuation = CharacterSet(charactersIn: "。！？～")
        let scalars = Array(content.unicodeScalars)
        guard let terminalIndex = scalars.firstIndex(where: { punctuation.contains($0) }) else {
            return (nil, nil)
        }

        let index = content.index(content.startIndex, offsetBy: terminalIndex + 1)
        let firstLine = String(content[..<index]).trimmed
        let rest = String(content[index...]).trimmed.nilIfEmpty

        guard firstLine.count <= 18 else {
            return (nil, nil)
        }

        return (firstLine.nilIfEmpty, rest)
    }
}

enum TreasureTimestampFormatter {
    static let shared = Formatter()

    final class Formatter {
        private let formatter: DateFormatter

        init() {
            formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "MMM d"
        }

        func string(from date: Date, ageInDays: Int?) -> String {
            let dateText = formatter.string(from: date).uppercased()
            if let ageInDays {
                return "\(dateText) · \(ageInDays)天"
            }
            return dateText
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
