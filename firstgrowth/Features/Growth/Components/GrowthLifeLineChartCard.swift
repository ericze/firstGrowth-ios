import Observation
import SwiftUI

struct GrowthLifeLineChartCard: View {
    @Bindable var store: GrowthStore
    private let formatter = GrowthFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("参考区间")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.secondaryText)

                    Text("用于帮助观察整体变化，不用于医学判断")
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
                                isVisible: store.viewState.isPrecisionVisible
                            )

                            if store.viewState.dataState == .empty {
                                GrowthChartEmptyState(metric: store.viewState.currentMetric)
                            }

                            if let selection = store.viewState.selection, store.viewState.isPrecisionVisible {
                                GrowthChartTooltipBubble(
                                    tooltip: selection.tooltip,
                                    xPosition: metrics.xPosition(for: selection.point.ageInDays)
                                )
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(chartGesture(plotWidth: metrics.size.width))
                    }
                    .frame(height: plotHeight)

                    GrowthChartAxisLabels(
                        ages: metrics.axisAgeMarks,
                        formatter: formatter
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

    var body: some View {
        VStack(spacing: 10) {
            Text("生命线还在等待第一条记录")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("先记录一条\(metric.title)数据，趋势会从这里安静地开始。")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }
}

private struct GrowthChartAxisLabels: View {
    let ages: [Int]
    let formatter: GrowthFormatter

    var body: some View {
        HStack {
            ForEach(Array(ages.enumerated()), id: \.offset) { index, age in
                Text(formatter.formatAxisLabel(ageInDays: age))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: index == 0 ? .leading : index == ages.count - 1 ? .trailing : .center)
            }
        }
    }
}
