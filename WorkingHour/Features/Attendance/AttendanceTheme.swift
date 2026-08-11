import SwiftUI

enum AttendanceTheme {
    static let accent = Color(red: 0.04, green: 0.52, blue: 0.96)
    static let mint = Color(red: 0.17, green: 0.76, blue: 0.55)
    static let coral = Color(red: 0.96, green: 0.43, blue: 0.48)
    static let ink = Color(red: 0.08, green: 0.11, blue: 0.17)
    static let secondaryInk = Color(red: 0.43, green: 0.47, blue: 0.54)

    static var background: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.96, blue: 1.00),
                Color(red: 0.91, green: 0.98, blue: 0.95),
                Color(red: 1.00, green: 0.91, blue: 0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AttendanceScreenBackground: View {
    var body: some View {
        AttendanceTheme.background
            .ignoresSafeArea()
    }
}

struct AttendancePanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.58))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.9), lineWidth: 1)
            }
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: AttendanceTheme.accent.opacity(0.06), radius: 14, y: 7)
    }
}

struct AttendanceTipBanner: View {
    let text: String

    var body: some View {
        AttendancePanel {
            HStack(spacing: 14) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.yellow)
                    .frame(width: 42, height: 42)
                    .background(.yellow.opacity(0.14))
                    .clipShape(Circle())

                Text(text)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AttendanceTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AttendanceProgressDots: View {
    let progress: Double

    private let columns = Array(repeating: GridItem(.fixed(17), spacing: 8), count: 10)

    var body: some View {
        let clampedProgress = min(max(progress, 0), 1)
        let filledCount = Int((clampedProgress * 30).rounded(.down))

        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<30, id: \.self) { index in
                Circle()
                    .fill(index < filledCount ? AttendanceTheme.accent : Color.white.opacity(0.76))
                    .overlay {
                        Circle()
                            .stroke(
                                index < filledCount ? AttendanceTheme.accent.opacity(0.18) : .gray.opacity(0.18),
                                lineWidth: 1
                            )
                    }
                    .frame(width: 17, height: 17)
                    .shadow(
                        color: index < filledCount ? AttendanceTheme.accent.opacity(0.22) : .clear,
                        radius: 3,
                        y: 1
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("今日进度")
        .accessibilityValue(
            Text(clampedProgress, format: .percent.precision(.fractionLength(0)))
        )
    }
}
