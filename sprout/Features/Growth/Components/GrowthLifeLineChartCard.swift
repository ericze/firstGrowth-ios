import Observation
import SwiftUI

struct GrowthLifeLineChartCard: View {
    @Bindable var store: GrowthStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("growth.chart.reference_title", en: "Reference range", zh: "参考区间"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.secondaryText)

                    Text(
                        L10n.text(
                            "growth.chart.reference_note",
                            en: "For observing overall changes only. Not for medical judgment.",
                            zh: "用于帮助观察整体变化，不用于医学判断"
                        )
                    )
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                }

                Spacer()

                GrowthRecordEntryButton {
                    store.handle(.tapEntry)
                }
            }

            GeometryReader { proxy in
                let plotHeight = max(proxy.size.height - 28, 120)
                let metrics = GrowthChartPlotMetrics(
                    size: CGSize(width: proxy.size.width, height: plotHeight),
                    points: store.viewState.points,
                    referenceBands: store.viewState.referenceBands,
                    currentAgeInDays: store.viewState.currentAgeInDays
                )

                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AppTheme.Colors.background.opacity(0.5))

                        ZStack {
                            GrowthChartReferenceRangeLayer(
                                metrics: metrics,
                                referenceBands: store.viewState.referenceBands
                            )

                            GrowthChartLineLayer(
                                metrics: metrics,
                                points: store.viewState.points
                            )

                            GrowthChartNodeLayer(
                                metrics: metrics,
                                points: store.viewState.points,
                                selection: store.viewState.selection
                            )

                            GrowthChartPrecisionOverlay(
                                metrics: metrics,
                                selection: store.viewState.selection,
                                labels: store.viewState.yAxisLabels,
                                metric: store.viewState.currentMetric,
                                isVisible: store.viewState.isPrecisionVisible
                            )

                            if store.viewState.dataState == .empty {
                                GrowthChartEmptyState(metric: store.viewState.currentMetric)
                            } else if store.viewState.dataState == .error {
                                GrowthChartErrorState(message: store.viewState.errorMessage ?? store.textRenderer.loadFailedMessage())
                            }

                            if let selection = store.viewState.selection, store.viewState.isPrecisionVisible {
                                GrowthChartTooltipBubble(
                                    ageText: store.textRenderer.tooltipAgeText(ageInDays: selection.tooltip.ageInDays),
                                    valueText: store.textRenderer.valueText(selection.tooltip.value, metric: selection.tooltip.metric),
                                    xPosition: metrics.xPosition(for: selection.point.ageInDays)
                                )
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(chartGesture(plotWidth: metrics.size.width))
                        .rootPagerGestureExclusion()
                    }
                    .frame(height: plotHeight)

                    GrowthChartAxisLabels(
                        ages: metrics.axisAgeMarks,
                        textRenderer: store.textRenderer
                    )
                }
            }
            .frame(height: 284)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private func chartGesture(plotWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if store.viewState.chartInteractionState == .idle {
                    store.handle(.beginScrubbing(locationX: value.location.x, plotWidth: plotWidth))
                } else {
                    store.handle(.updateScrubbing(locationX: value.location.x, plotWidth: plotWidth))
                }
            }
            .onEnded { _ in
                store.handle(.endScrubbing)
            }
    }
}

struct GrowthChartPlotMetrics {
    let size: CGSize
    let domainAgeRange: ClosedRange<Double>
    let domainValueRange: ClosedRange<Double>
    let axisAgeMarks: [Int]

    init(
        size: CGSize,
        points: [GrowthPoint],
        referenceBands: [GrowthReferenceBandPoint],
        currentAgeInDays: Int
    ) {
        self.size = size

        let maxAge = max(
            currentAgeInDays,
            points.last?.ageInDays ?? 0,
            referenceBands.last?.ageInDays ?? 0,
            120
        )
        domainAgeRange = 0...Double(maxAge)

        let allValues = points.map(\.value) + referenceBands.flatMap { [$0.lower, $0.upper] }
        let minValue = allValues.min() ?? 0
        let maxValue = allValues.max() ?? 1
        let padding = max((maxValue - minValue) * 0.12, 0.6)
        domainValueRange = (minValue - padding)...(maxValue + padding)

        axisAgeMarks = [0, maxAge / 2, maxAge]
    }

    func xPosition(for ageInDays: Int) -> CGFloat {
        guard domainAgeRange.upperBound > domainAgeRange.lowerBound else { return size.width / 2 }
        let ratio = (Double(ageInDays) - domainAgeRange.lowerBound) / (domainAgeRange.upperBound - domainAgeRange.lowerBound)
        return CGFloat(ratio) * size.width
    }

    func yPosition(for value: Double) -> CGFloat {
        guard domainValueRange.upperBound > domainValueRange.lowerBound else { return size.height / 2 }
        let ratio = (value - domainValueRange.lowerBound) / (domainValueRange.upperBound - domainValueRange.lowerBound)
        return size.height - CGFloat(ratio) * size.height
    }

    func point(for growthPoint: GrowthPoint) -> CGPoint {
        CGPoint(
            x: xPosition(for: growthPoint.ageInDays),
            y: yPosition(for: growthPoint.value)
        )
    }

    func yPosition(for label: GrowthYAxisLabel) -> CGFloat {
        CGFloat(label.normalizedY) * size.height
    }
}

private struct GrowthChartEmptyState: View {
    let metric: GrowthMetric
    private let textRenderer = GrowthTextRenderer()

    var body: some View {
        VStack(spacing: 10) {
            Text(L10n.text("growth.chart.empty.title", en: "The line is waiting for its first record", zh: "生命线还在等待第一条记录"))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(
                L10n.format(
                    "growth.chart.empty.body_format",
                    locale: Locale.autoupdatingCurrent,
                    en: "Start with one %@ record. The trend can begin quietly from here.",
                    zh: "先记录一条%@数据，趋势会从这里安静地开始。",
                    arguments: [textRenderer.metricTitle(metric)]
                )
            )
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }
}

private struct GrowthChartErrorState: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Text(L10n.text("growth.chart.error.title", en: "Couldn't load this chart", zh: "这张图表暂时没有加载成功"))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(message)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }
}

private struct GrowthChartAxisLabels: View {
    let ages: [Int]
    let textRenderer: GrowthTextRenderer

    var body: some View {
        HStack {
            ForEach(Array(ages.enumerated()), id: \.offset) { index, age in
                Text(textRenderer.axisAgeText(ageInDays: age))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: index == 0 ? .leading : index == ages.count - 1 ? .trailing : .center)
            }
        }
    }
}
