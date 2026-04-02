import Foundation

struct LocaleFormatter {
    let locale: Locale
    let calendar: Calendar
    let localizationService: LocalizationService

    enum AgeStyle {
        case axis
        case detail
    }

    init(
        locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent,
        localizationService: LocalizationService? = nil
    ) {
        var resolvedCalendar = calendar
        resolvedCalendar.locale = locale

        self.locale = locale
        self.calendar = resolvedCalendar
        self.localizationService = localizationService ?? LocalizationService(locale: locale)
    }

    func integer(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    func decimal(_ value: Double, minFractionDigits: Int = 0, maxFractionDigits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minFractionDigits
        formatter.maximumFractionDigits = maxFractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    func list(_ items: [String]) -> String {
        guard !items.isEmpty else { return "" }

        let formatter = ListFormatter()
        formatter.locale = locale
        return formatter.string(from: items) ?? items.joined(separator: ", ")
    }

    func relativeDate(from date: Date, to referenceDate: Date = .now) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: referenceDate)
    }

    func date(_ date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .none) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: date)
    }

    func duration(
        from timeInterval: TimeInterval,
        allowedUnits: NSCalendar.Unit = [.hour, .minute],
        unitsStyle: DateComponentsFormatter.UnitsStyle = .full
    ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = allowedUnits
        formatter.unitsStyle = unitsStyle
        formatter.calendar = calendar
        formatter.zeroFormattingBehavior = [.dropLeading]
        return formatter.string(from: max(timeInterval, 0)) ?? ""
    }

    func durationText(
        seconds: Double,
        unitsStyle: DateComponentsFormatter.UnitsStyle = .abbreviated
    ) -> String {
        duration(from: seconds, allowedUnits: [.hour, .minute], unitsStyle: unitsStyle)
    }

    func minuteDurationText(_ minutes: Int, unitsStyle: DateComponentsFormatter.UnitsStyle = .abbreviated) -> String {
        duration(
            from: TimeInterval(max(minutes, 0) * 60),
            allowedUnits: [.minute],
            unitsStyle: unitsStyle
        )
    }

    func localizedSymbolValue(
        _ value: Double,
        symbol: String,
        minFractionDigits: Int = 0,
        maxFractionDigits: Int = 1
    ) -> String {
        "\(decimal(value, minFractionDigits: minFractionDigits, maxFractionDigits: maxFractionDigits))\(symbol)"
    }

    func localizedSymbolValue(_ value: Int, symbol: String) -> String {
        "\(integer(value))\(symbol)"
    }

    func relativeDay(from date: Date, to referenceDate: Date = .now) -> String {
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: referenceDate)
        let dayDelta = max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 0)

        if dayDelta == 0 {
            return L10n.text(
                "common.relative.today",
                service: localizationService,
                en: "Today",
                zh: "今天"
            )
        }

        if dayDelta < 30 {
            return L10n.format(
                "common.relative.days_ago_format",
                service: localizationService,
                locale: locale,
                en: "%@ ago",
                zh: "%@前",
                arguments: [localizedDayCount(dayDelta, style: .detail)]
            )
        }

        let monthDelta = max(calendar.dateComponents([.month], from: date, to: referenceDate).month ?? 0, 1)
        if monthDelta < 12 {
            return L10n.format(
                "common.relative.months_ago_format",
                service: localizationService,
                locale: locale,
                en: "%@ ago",
                zh: "%@前",
                arguments: [localizedMonthCount(monthDelta, style: .detail)]
            )
        }

        let yearDelta = max(calendar.dateComponents([.year], from: date, to: referenceDate).year ?? 1, 1)
        return L10n.format(
            "common.relative.years_ago_format",
            service: localizationService,
            locale: locale,
            en: "%@ ago",
            zh: "%@前",
            arguments: [localizedYearCount(yearDelta, style: .detail)]
        )
    }

    func ageText(fromDays ageInDays: Int, style: AgeStyle = .detail) -> String {
        if ageInDays < 30 {
            return localizedDayCount(max(ageInDays, 0), style: style)
        }

        let months = max(ageInDays / 30, 0)
        if months < 24 {
            return localizedMonthCount(months, style: style)
        }

        let years = months / 12
        let remainingMonths = months % 12

        let yearText = localizedYearCount(years, style: style)
        guard remainingMonths > 0 else {
            return yearText
        }

        return "\(yearText)\(localizedMonthCount(remainingMonths, style: style))"
    }

    func measurement<UnitType: Dimension>(
        _ value: Double,
        unit: UnitType,
        unitStyle: MeasurementFormatter.UnitStyle = .short
    ) -> String {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitStyle = unitStyle
        return formatter.string(from: Measurement(value: value, unit: unit))
    }

    private func localizedDayCount(_ count: Int, style: AgeStyle) -> String {
        localizedComponent(
            day: count,
            style: style,
            enFull: "day",
            enAbbreviated: "d",
            zhFull: "天",
            zhAbbreviated: "天"
        )
    }

    private func localizedMonthCount(_ count: Int, style: AgeStyle) -> String {
        localizedComponent(
            month: count,
            style: style,
            enFull: "month",
            enAbbreviated: "mo",
            zhFull: "个月",
            zhAbbreviated: "月"
        )
    }

    private func localizedYearCount(_ count: Int, style: AgeStyle) -> String {
        localizedComponent(
            year: count,
            style: style,
            enFull: "year",
            enAbbreviated: "yr",
            zhFull: "岁",
            zhAbbreviated: "岁"
        )
    }

    private func localizedComponent(
        day: Int? = nil,
        month: Int? = nil,
        year: Int? = nil,
        style: AgeStyle,
        enFull: String,
        enAbbreviated: String,
        zhFull: String,
        zhAbbreviated: String
    ) -> String {
        let count = day ?? month ?? year ?? 0
        let countText = integer(count)

        switch localizationService.language {
        case .english:
            switch style {
            case .axis:
                return "\(countText) \(enAbbreviated)"
            case .detail:
                let unit = count == 1 ? enFull : "\(enFull)s"
                return "\(countText) \(unit)"
            }
        case .simplifiedChinese:
            switch style {
            case .axis:
                return "\(countText)\(zhAbbreviated)"
            case .detail:
                return "\(countText)\(zhFull)"
            }
        }
    }
}
