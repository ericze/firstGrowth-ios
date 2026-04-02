import SwiftUI

struct TreasureScrollOffsetReader: View {
    static let coordinateSpaceName = "treasure-scroll-space"

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: TreasureScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named(Self.coordinateSpaceName)).minY
                )
        }
        .frame(height: 0)
    }
}

struct TreasureScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
