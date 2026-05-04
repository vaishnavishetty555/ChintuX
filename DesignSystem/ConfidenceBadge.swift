import SwiftUI

/// PRD §6.5 — AI Doctor confidence pill.
struct ConfidenceBadge: View {
    enum Level: String, Codable, CaseIterable {
        case low, medium, high
        var label: String {
            switch self {
            case .low:    return "Low confidence"
            case .medium: return "Medium confidence"
            case .high:   return "High confidence"
            }
        }
        var dotColor: Color {
            switch self {
            case .low:    return PawlyColors.alert
            case .medium: return PawlyColors.peach
            case .high:   return PawlyColors.sage
            }
        }
    }

    let level: Level

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(level.dotColor).frame(width: 8, height: 8)
            Text(level.label)
                .font(PawlyFont.caption)
                .foregroundStyle(PawlyColors.ink)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(PawlyColors.surface)
        )
        .overlay(
            Capsule().stroke(PawlyColors.sand, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
