import SwiftUI

/// PRD §6.4 & §9 — Calendar status indicator. Uses color AND shape so information
/// is conveyed without relying on color alone (a11y requirement).
struct StatusDot: View {
    enum Status {
        case completed   // Forest, filled circle
        case upcoming    // Sand, hollow circle
        case missed      // Alert, filled circle with inner dot (triangle accent)
    }

    let status: Status
    var size: CGFloat = 8

    var body: some View {
        ZStack {
            switch status {
            case .completed:
                Circle().fill(PawlyColors.forest)
            case .upcoming:
                Circle().stroke(PawlyColors.sand, lineWidth: 1.5)
            case .missed:
                Circle().fill(PawlyColors.alert)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.35, height: size * 0.35)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(a11yLabel)
    }

    private var a11yLabel: String {
        switch status {
        case .completed: return "Completed"
        case .upcoming:  return "Upcoming"
        case .missed:    return "Missed"
        }
    }
}
