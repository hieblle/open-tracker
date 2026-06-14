import SwiftUI

/// A thin horizontal stacked bar showing relative proportions.
struct ProportionBar: View {
    struct Segment: Identifiable {
        let id = UUID()
        let value: Double
        let color: Color
    }

    let segments: [Segment]
    var height: CGFloat = 10

    var body: some View {
        let total = max(segments.reduce(0) { $0 + $1.value }, 0.0001)
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(segments) { segment in
                    segment.color
                        .frame(width: geo.size.width * CGFloat(segment.value / total))
                }
            }
        }
        .frame(height: height)
        .background(Color.secondary.opacity(0.15))
        .clipShape(Capsule())
    }
}
