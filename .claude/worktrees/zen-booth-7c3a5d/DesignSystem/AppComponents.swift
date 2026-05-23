import SwiftUI

// MARK: - App Card

/// Standard card: white surface, warm shadow, no borders.
/// Used as the base card for most content sections.
struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(PawlyColors.surface)
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
            )
    }
}

// MARK: - App Badge

/// Compact pill badge with colored tint.
struct AppBadge: View {
    let text: String
    let color: Color
    var textColor: Color? = nil

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(textColor ?? color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.14)))
    }
}

// MARK: - App Tag (smaller)

/// Small colored tag/chip — for inline labels.
struct AppTag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}

// MARK: - App Stat Tile

/// Stat display: icon + value + label. Used in grids.
struct AppStatTile: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: action ?? {}) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PawlyColors.slate)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(PawlyColors.surface)
            )
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - App Section Header

/// Section title with optional right-side action.
struct AppSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    var icon: String? = nil
    var iconColor: Color = PawlyColors.forest

    var body: some View {
        HStack(spacing: 0) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .padding(.trailing, 6)
            }

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(PawlyColors.ink)

            Spacer()

            if let action, let actionLabel {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionLabel)
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(PawlyColors.forest)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - App Icon Button

/// Circle button with SF Symbol — for actions in headers.
struct AppIconButton: View {
    let icon: String
    var color: Color = PawlyColors.forest
    var size: CGFloat = 36
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.10))
                    .frame(width: size, height: size)
                Image(systemName: icon)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(color)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Empty State

/// Centered empty state with icon + title + subtitle + optional CTA.
struct AppEmptyState: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.10))
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PawlyColors.ink)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(PawlyColors.slate)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(PawlyColors.forest))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Pet Avatar (alias)

/// Pet avatar with photo/emoji fallback, accent background.
struct PetAvatarDTO: View {
    let pet: PetDTO
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            if let photoURL = pet.photoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(hex: pet.accentHex)
                        .overlay(
                            Text(Species(rawValue: pet.speciesRaw)?.emoji ?? "🐾")
                                .font(.system(size: size * 0.4))
                        )
                }
            } else {
                Color(hex: pet.accentHex)
                    .overlay(
                        Text(Species(rawValue: pet.speciesRaw)?.emoji ?? "🐾")
                            .font(.system(size: size * 0.4))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

// MARK: - App Avatar

/// Pet avatar with optional accent color ring.
struct AppAvatar: View {
    let name: String
    let accentHex: String
    var photoURL: String? = nil
    var size: CGFloat = 48
    var showRing: Bool = true

    var body: some View {
        ZStack {
            if let photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(hex: accentHex)
                        .overlay(
                            Text(name.prefix(1).uppercased())
                                .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        )
                }
            } else {
                Color(hex: accentHex)
                    .overlay(
                        Text(name.prefix(1).uppercased())
                            .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
        .overlay(
            Group {
                if showRing {
                    RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                        .stroke(Color.white, lineWidth: 2)
                }
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

// MARK: - App Tappable Tile

/// Large tappable tile with icon, label, and optional count.
struct AppTile: View {
    let icon: String
    let iconColor: Color
    let label: String
    var count: Int? = nil
    var isActive: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isActive ? iconColor : iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isActive ? .white : iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PawlyColors.ink)

                    if let count, count > 0 {
                        Text("\(count)\u{D7} logged")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(PawlyColors.slate)
                    }
                }

                Spacer()

                if let count, count > 0 {
                    AppBadge(text: "\(count)", color: iconColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(isActive ? iconColor.opacity(0.08) : PawlyColors.surface)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dot Grid Pattern

/// Subtle dot grid background pattern.
struct DotGridPattern: View {
    var spacing: CGFloat = 24
    var dotSize: CGFloat = 1.5
    var opacity: CGFloat = 0.06

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let cols = Int(size.width / spacing) + 1
                let rows = Int(size.height / spacing) + 1

                for col in 0..<cols {
                    for row in 0..<rows {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing
                        context.fill(
                            Circle().path(in: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                            with: .color(Color.black.opacity(opacity))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - App Primary Button

/// Primary CTA button with forest green fill.
struct AppPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(isDisabled ? PawlyColors.forest.opacity(0.45) : PawlyColors.forest)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - App Secondary Button

/// Secondary button with soft fill.
struct AppSecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(PawlyColors.forest)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(PawlyColors.forestSoft)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Info Row

/// Label + value row for settings/info displays.
struct AppInfoRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var iconColor: Color = PawlyColors.forest

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.10))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(iconColor)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PawlyColors.slate)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PawlyColors.ink)
            }

            Spacer()
        }
    }
}

// MARK: - App Divider

struct AppDivider: View {
    var body: some View {
        Rectangle()
            .fill(PawlyColors.divider)
            .frame(height: 0.5)
    }
}

// MARK: - Paw Buddy Care Components

// MARK: - Wellness Ring

/// Animated circular wellness ring with multi-segment progress.
struct WellnessRing: View {
    let wellness: Int
    let size: CGFloat
    let strokeWidth: CGFloat
    var segments: [(label: String, value: Int, color: Color)] = [
        ("Nutrition", 92, PawlyColors.wellnessNutrition),
        ("Activity",  78, PawlyColors.wellnessActivity),
        ("Hydration", 85, PawlyColors.wellnessHydration),
        ("Mood",      95, PawlyColors.wellnessMood),
    ]

    private var circumference: CGFloat {
        .pi * (size - strokeWidth)
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.black.opacity(0.05), lineWidth: strokeWidth)

            // Segmented ring
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let r = (size - strokeWidth) / 2
                var startAngle = Angle.degrees(-90)
                let totalValue = segments.reduce(0) { $0 + $1.value }
                let scaledTotal = CGFloat(wellness) / 100.0

                for segment in segments {
                    let proportion = CGFloat(segment.value) / CGFloat(totalValue)
                    let arcLength = proportion * circumference * scaledTotal
                    let gap: CGFloat = 4

                    var path = Path()
                    path.addArc(
                        center: center,
                        radius: r,
                        startAngle: startAngle,
                        endAngle: Angle(radians: startAngle.radians + (arcLength / r)),
                        clockwise: false
                    )

                    context.stroke(
                        path,
                        with: .color(segment.color),
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )

                    startAngle = Angle(radians: startAngle.radians + (arcLength + gap) / r)
                }
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 2) {
                Text("Wellness")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .tracking(1)
                    .textCase(.uppercase)
                Text("\(wellness)")
                    .font(PawlyFont.displayNumber)
                    .foregroundStyle(PawlyColors.ink)
            }
        }
    }
}

// MARK: - Confetti Particle View

/// Confetti burst effect for task completion.
struct ConfettiView: View {
    let trigger: Bool

    @State private var particles: [AnimatedParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: 8, height: 8)
                    .offset(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
        }
        .onChange(of: trigger) { _, newValue in
            if newValue { startAnimation() }
        }
        .onAppear { if trigger { startAnimation() } }
    }

    private func startAnimation() {
        let colors: [Color] = [
            PawlyColors.peachAccent, PawlyColors.peachAccentSoft,
            PawlyColors.wellnessNutrition, PawlyColors.wellnessActivity,
            PawlyColors.wellnessHydration, Color(hex: "#F5B5C8")
        ]
        particles = (0..<12).map { i in
            let angle = Double(i) / 12.0 * 2 * .pi
            let distance: CGFloat = 30 + CGFloat.random(in: 0...18)
            return AnimatedParticle(
                id: i,
                color: colors[i % colors.count],
                x: cos(angle) * distance,
                y: sin(angle) * distance - 10,
                opacity: 1.0
            )
        }
        withAnimation(.easeOut(duration: 0.7)) {
            for i in particles.indices {
                particles[i].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            particles = []
        }
    }
}

private struct AnimatedParticle: Identifiable {
    let id: Int
    let color: Color
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

// MARK: - Pet Selector Chip

/// Horizontal pet selector chip showing pet avatar and name.
struct PetSelectorChip: View {
    let pet: PetDTO
    let isSelected: Bool
    var wellnessPercent: Int? = nil
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                ZStack {
                    PetAvatarDTO(pet: pet, size: 36)
                    if let wellness = wellnessPercent {
                        Circle()
                            .trim(from: 0, to: CGFloat(wellness) / 100.0)
                            .stroke(Color(hex: pet.accentHex), lineWidth: 3)
                            .frame(width: 42, height: 42)
                            .rotationEffect(.degrees(-90))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(pet.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(PawlyColors.ink)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: pet.accentHex))
                            .frame(width: 5, height: 5)
                        Text(Species(rawValue: pet.speciesRaw)?.displayName ?? pet.speciesRaw)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(PawlyColors.inkSoft)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? PawlyColors.surface : Color.white.opacity(0.45))
            )
            .shadow(color: isSelected ? Color.black.opacity(0.06) : .clear, radius: 4, x: 0, y: 2)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.black.opacity(0.06) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Pet Chip Button

struct AddPetChipButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text("Add pet")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(PawlyColors.inkSoft)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.45))
            )
            .overlay(
                Capsule()
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                    .foregroundStyle(Color.black.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Streak Bar

/// Weekly streak indicator with check marks.
struct StreakBar: View {
    let streakCount: Int
    var days: [Bool] = Array(repeating: false, count: 7) // last 7 days, today is last

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, done in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(done ? PawlyColors.peachAccent : Color.white.opacity(0.7))
                            .frame(width: 28, height: 28)
                            .shadow(color: done ? PawlyColors.peachAccent.opacity(0.4) : .clear, radius: 3, x: 0, y: 2)
                        if done {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    Text(["M","T","W","T","F","S","S"][index])
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(index == 5 ? PawlyColors.ink : PawlyColors.inkSoft)
                }
            }
        }
    }
}

// MARK: - Home Streak Bar

/// Compact streak card for the home screen header.
struct HomeStreakBar: View {
    let streak: Int
    let days: [Bool]

    private let flameColor = Color(hex: "#E8B65C")

    /// Real weekday letters for the last 7 days (index 0 = 6 days ago, index 6 = today).
    private var dayLabels: [String] {
        let cal = Calendar.current
        let today = Date()
        // weekday: 1=Sun 2=Mon 3=Tue 4=Wed 5=Thu 6=Fri 7=Sat
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]
        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: -(6 - offset), to: today) ?? today
            let wd = cal.component(.weekday, from: day)
            return symbols[wd - 1]
        }
    }

    /// Today is always the last element in the rolling window.
    private let todayIndex = 6

    var body: some View {
        VStack(spacing: 0) {
            // Top row: flame + title + streak number
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(streak > 0 ? flameColor.opacity(0.12) : Color.black.opacity(0.05))
                        .frame(width: 38, height: 38)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(streak > 0 ? flameColor : PawlyColors.inkSoft.opacity(0.35))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(streak > 0 ? "\(streak) day streak 🔥" : "Start your streak")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(PawlyColors.ink)
                    Text(streak > 0 ? "You're on a roll — keep logging!" : "Log care daily to build a streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(PawlyColors.inkSoft)
                }

                Spacer()

                if streak > 0 {
                    Text("\(streak)")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(flameColor)
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.black.opacity(0.055))
                .frame(height: 0.5)
                .padding(.horizontal, 14)

            // Week dots row
            HStack(spacing: 0) {
                ForEach(0..<min(days.count, 7), id: \.self) { i in
                    let done  = days[i]
                    let isToday = i == todayIndex
                    VStack(spacing: 5) {
                        ZStack {
                            // Background fill
                            Circle()
                                .fill(
                                    done      ? flameColor :
                                    isToday   ? flameColor.opacity(0.14) :
                                                Color.black.opacity(0.06)
                                )
                                .frame(width: 28, height: 28)
                            // Today ring (when no activity yet)
                            if isToday && !done {
                                Circle()
                                    .strokeBorder(flameColor.opacity(0.55), lineWidth: 1.5)
                                    .frame(width: 28, height: 28)
                            }
                            if done {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        Text(dayLabels[i])
                            .font(.system(size: 10, weight: isToday ? .bold : .semibold))
                            .foregroundStyle(
                                done    ? flameColor :
                                isToday ? flameColor :
                                          PawlyColors.inkSoft.opacity(0.5)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - AI Tip Card

/// AI buddy tip card with gradient background.
struct AITipCard: View {
    let tip: String
    let tag: String
    var onRefresh: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#9B7FD4"))
                }

                Text(tag)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.6)))

                Spacer()

                if let onRefresh {
                    Button(action: onRefresh) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(PawlyColors.ink)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("\"\(tip)\"")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
                .lineSpacing(3)

            Text("Tap for next")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: "#E6DFF6"), Color(hex: "#DCEDF5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous))
    }
}

// MARK: - Photo Memory Tile

/// Placeholder photo memory tile with gradient.
struct PhotoMemoryTile: View {
    let tone: Int
    let emoji: String
    let badge: String?
    var size: CGFloat = 130

    private var cardTone: PawlyColors.CardTone {
        PawlyColors.CardTone(rawValue: tone % 7) ?? .peach
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [cardTone.bg, cardTone.tint.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Diagonal stripe overlay
            GeometryReader { geo in
                Path { path in
                    var x: CGFloat = -size
                    while x < size * 2 {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + size, y: size))
                        x += 17
                    }
                }
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
            }

            // Emoji center
            Text(emoji)
                .font(.system(size: size * 0.42))

            // Badge
            if let badge {
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.85)))
                    .position(x: size - 14, y: 10)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Next Up Card

/// Highlighted "next task" card with primary accent.
struct NextUpCard: View {
    let icon: String
    let iconColor: Color
    let time: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Next up \u{2022} \(time)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(iconColor)
                    .textCase(.uppercase)
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                // Remind action
            } label: {
                Text("Remind")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(iconColor))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(iconColor.opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - Progress Bar

struct PBProgressBar: View {
    let value: Double // 0-100
    let color: Color
    var height: CGFloat = 6
    var bgColor: Color = Color.black.opacity(0.08)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(bgColor)
                RoundedRectangle(cornerRadius: 999)
                    .fill(color)
                    .frame(width: geo.size.width * min(max(value, 0), 100) / 100)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Section Title Row

struct PBSectionTitle: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(PawlyFont.sectionTitle)
                .foregroundStyle(PawlyColors.ink)

            Spacer()

            if let action, let onAction {
                Button(action: onAction) {
                    HStack(spacing: 3) {
                        Text(action)
                            .font(.system(size: 12.5, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(PawlyColors.inkSoft)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Pet Mood Badge

struct MoodBadge: View {
    let mood: String
    let emoji: String

    var body: some View {
        HStack(spacing: 6) {
            Text("\(mood) \(emoji)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
        }
    }
}

// MARK: - Add Button (Center FAB)

struct PBAddButton: View {
    let action: () -> Void
    var color: Color = PawlyColors.navy

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(y: -1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Check Button (Todo)

struct CheckButton: View {
    let done: Bool
    let primary: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(done ? primary : .clear)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(done ? .clear : Color.black.opacity(0.18), lineWidth: 2)
                    )
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chip / Badge Tag

struct PBChip: View {
    let text: String
    var tone: Color = PawlyColors.peachAccentSoft
    var textColor: Color = PawlyColors.ink
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
            }
            Text(text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(tone))
    }
}

// MARK: - Screen Header

struct PBCScreenHeader: View {
    let title: String
    let subtitle: String
    var onBack: (() -> Void)? = nil
    var right: AnyView? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let onBack {
                    Button(action: onBack) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "chevron.left").font(.system(size: 16, weight: .medium)).foregroundStyle(PawlyColors.ink))
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                } else {
                    Spacer().frame(width: 36)
                }
                Spacer()
                if let right = right {
                    AnyView(right)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.m)

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(PawlyColors.ink)
                .padding(.horizontal, Spacing.screenHorizontal)

            Text(subtitle)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(PawlyColors.inkSoft)
                .tracking(0.5)
                .padding(.horizontal, Spacing.screenHorizontal)
        }
    }
}

// MARK: - Progress Bar

struct PBCProgressBar: View {
    let value: Double
    let color: Color
    var background: Color = Color(hex: "#E8E0D5").opacity(0.5)
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(background)
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(color)
                    .frame(width: geo.size.width * min(value / 100, 1))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Gamification: Pet Level Bar

struct PBGLevelBar: View {
    let pet: PetDTO
    let streak: Int
    let treats: Int
    let primary: Color
    let primaryDeep: Color

    private var level: Int {
        let xpPerLevel = 50
        let totalXP = (streak * 8) + (treats * 1)
        return max(1, totalXP / xpPerLevel + 1)
    }

    private var xpInLevel: Int {
        let xpPerLevel = 50
        let totalXP = (streak * 8) + (treats * 1)
        return totalXP % xpPerLevel
    }

    private var pct: Double {
        Double(xpInLevel) / 50.0 * 100.0
    }

    private var title: String {
        let titles = ["Newbie", "Apprentice", "Caregiver", "Pet whisperer", "Wellness sage", "Soul-bonded"]
        return titles[min(level - 1, titles.count - 1)]
    }

    private var levelCircleWidth: CGFloat { 48 }
    private var levelCircleSize: CGFloat { 38 }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 3)
                    .frame(width: levelCircleWidth, height: levelCircleWidth)
                Circle()
                    .trim(from: 0, to: CGFloat(pct) / 100)
                    .stroke(primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: levelCircleWidth, height: levelCircleWidth)
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill(Color(hex: "#2A2520"))
                    .frame(width: levelCircleSize, height: levelCircleSize)
                Text("L\(level)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#FFD685"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(pet.name) the \(title)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .tracking(0.5)
                    .textCase(.uppercase)
                Text("\(xpInLevel)/50 XP to L\(level + 1)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                PBCProgressBar(value: pct, color: primary, background: Color.white.opacity(0.2), height: 5)
                    .padding(.top, 4)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(treats)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#FFD685"))
                Text("treats")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color(hex: "#2A2520"))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Gamification: Daily Quests

struct PBGDailyQuests: View {
    let pet: PetDTO
    @Binding var treats: Int
    let primary: Color

    @State private var quests: [QuestItem] = []

    struct QuestItem: Identifiable {
        let id: String
        let label: String
        let reward: Int
        let icon: String
        let tone: Int
        var done: Bool
    }

    private var totalCount: Int { quests.count }
    private var doneCount: Int { quests.filter { $0.done }.count }
    private var remaining: Int {
        quests.filter { !$0.done }.reduce(0) { $0 + $1.reward }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily quests")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
                Spacer()
                Text("\(doneCount)/\(totalCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "#FFF0CC"))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text("🎯")
                                .font(.system(size: 22))
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(remaining) treats up for grabs")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(PawlyColors.ink)
                        Text("Resets at midnight")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(PawlyColors.inkSoft)
                    }
                    Spacer()
                    PBChip(text: "today", tone: Color.white, textColor: primary, icon: "clock")
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FFF0CC"), Color(hex: "#FFE2D4")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .padding(.horizontal, Spacing.screenHorizontal)

                ForEach(Array(quests.enumerated()), id: \.element.id) { idx, quest in
                    if idx > 0 {
                        Divider()
                            .padding(.horizontal, Spacing.screenHorizontal)
                    }
                    questRow(quest)
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            .padding(.horizontal, Spacing.screenHorizontal)
        }
        .onAppear { loadQuests() }
    }

    private func questRow(_ quest: QuestItem) -> some View {
        let cardTone = PawlyColors.CardTone(rawValue: quest.tone % 7) ?? .peach
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(cardTone.bg)
                    .frame(width: 34, height: 34)
                Image(systemName: questIcon(quest.icon))
                    .font(.system(size: 17))
                    .foregroundStyle(cardTone.tint)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(quest.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                    .lineLimit(2)
                    .strikethrough(quest.done, color: PawlyColors.inkMuted)
                Text("🦴 +\(quest.reward) treats")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }

            Spacer()

            Button {
                claimQuest(quest)
            } label: {
                Text(quest.done ? "✓ Done" : "Claim")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(quest.done ? Color(hex: "#3A9B7E") : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(quest.done ? Color(hex: "#DCEBDD") : primary))
            }
            .disabled(quest.done)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .opacity(quest.done ? 0.6 : 1)
    }

    private func questIcon(_ icon: String) -> String {
        switch icon {
        case "bowl": return "fork.knife"
        case "camera": return "camera.fill"
        case "heart": return "heart.fill"
        case "drop": return "drop.fill"
        default: return "star.fill"
        }
    }

    private func loadQuests() {
        quests = [
            QuestItem(id: "q1", label: "Log breakfast on time",    reward: 3, icon: "bowl",   tone: 1, done: false),
            QuestItem(id: "q2", label: "Take a memory photo",       reward: 5, icon: "camera", tone: 2, done: false),
            QuestItem(id: "q3", label: "Give 10 head pats",         reward: 5, icon: "heart",  tone: 0, done: false),
            QuestItem(id: "q4", label: "Refresh water bowl twice",  reward: 2, icon: "drop",   tone: 4, done: false),
        ]
    }

    private func claimQuest(_ quest: QuestItem) {
        if let idx = quests.firstIndex(where: { $0.id == quest.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                quests[idx].done = true
                treats += quest.reward
                Haptics.success()
            }
        }
    }
}

// MARK: - Gamification: Pet Pet Ritual

struct PBGPetRitual: View {
    let pet: PetDTO
    @Binding var treats: Int

    @State private var patCount: Int = 0
    @State private var hearts: [HeartParticle] = []
    @State private var wiggle: Bool = false

    private let dailyGoal = 10
    private let emojis = ["💛", "💖", "✨", "💕", "🌟", "💗"]

    struct HeartParticle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let emoji: String
    }

    private var pct: Double { Double(patCount) / Double(dailyGoal) * 100 }
    private var done: Bool { patCount >= dailyGoal }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily ritual")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .tracking(0.5)
                        .textCase(.uppercase)
                    Text(done ? "\(pet.name) is glowing! ✨" : "Give \(pet.name) some love")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(PawlyColors.ink)
                }
                Spacer()
                PBChip(text: "\(patCount)/\(dailyGoal)", tone: Color.white, textColor: PawlyColors.peachAccent, icon: "pawprint.fill")
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            // Tap area
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.5))
                    .frame(height: 120)

                Text(Species(rawValue: pet.speciesRaw)?.emoji ?? "🐾")
                    .font(.system(size: 64))
                    .scaleEffect(wiggle ? 1.1 : 1.0)
                    .rotationEffect(wiggle ? .degrees(-6) : .degrees(0))
                    .animation(.spring(response: 0.18, dampingFraction: 0.5), value: wiggle)

                ForEach(hearts) { heart in
                    Text(heart.emoji)
                        .font(.system(size: 22))
                        .position(x: heart.x, y: heart.y)
                        .transition(.opacity)
                }

                Text(done ? "Tap for more love 💖" : "Tap to pet")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
            }
            .frame(height: 120)
            .contentShape(Rectangle())
            .onTapGesture { tapPet() }
            .padding(.horizontal, Spacing.screenHorizontal)

            PBCProgressBar(value: pct, color: PawlyColors.peachAccent, background: Color.white.opacity(0.6))
                .padding(.horizontal, Spacing.screenHorizontal)

            if done {
                Text("🎉 +5 treats earned • \(pet.name)'s mood +3")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(PawlyColors.peachAccent)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(Color(hex: "#FFFBF3"))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private func tapPet() {
        let emoji = emojis.randomElement() ?? "💛"
        let x = CGFloat.random(in: 30...80)
        let y = CGFloat.random(in: 30...90)
        hearts.append(HeartParticle(x: x, y: y, emoji: emoji))

        wiggle = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { wiggle = false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            hearts.removeAll { $0.emoji == emoji && $0.x == x && $0.y == y }
        }

        if patCount < dailyGoal {
            patCount += 1
            if patCount == dailyGoal {
                treats += 5
                Haptics.success()
            }
        }
    }
}

// MARK: - Gamification: Daily Surprise

struct PBGDailySurprise: View {
    let pet: PetDTO
    @Binding var treats: Int

    @State private var opened: Bool = false
    @State private var reward: Reward? = nil

    struct Reward {
        let emoji: String
        let label: String
    }

    private let rewards: [Reward] = [
        Reward(emoji: "🦴", label: "+5 treats"),
        Reward(emoji: "⭐", label: "+10 XP boost"),
        Reward(emoji: "🎁", label: "New AI tip unlocked"),
        Reward(emoji: "🌟", label: "Wellness +2"),
    ]

    var body: some View {
        Button {
            if !opened {
                openSurprise()
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    Text(opened ? (reward?.emoji ?? "🎁") : "🎁")
                        .font(.system(size: 32))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's surprise")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .tracking(0.5)
                        .textCase(.uppercase)
                    Text(opened ? (reward?.label ?? "Already opened") : "Tap to open ✨")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(PawlyColors.ink)
                    Text(opened ? "Come back tomorrow" : "A little something for \(pet.name)")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(PawlyColors.inkSoft)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(
                        opened
                        ? LinearGradient(colors: [Color(hex: "#DCEBDD"), Color(hex: "#FFFBF3")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(hex: "#E6DFF6"), Color(hex: "#FFE2D4")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private func openSurprise() {
        reward = rewards.randomElement() ?? rewards[0]
        opened = true
        if reward?.emoji == "🦴" {
            treats += 5
        }
        Haptics.success()
    }
}

// MARK: - Gamification: Mood Game (Treat Hunt)

struct PBGMoodGame: View {
    let pet: PetDTO
    @Binding var treats: Int

    @State private var boxes: [Box] = (0..<3).map { Box(index: $0, won: $0 == 0, revealed: false, picked: false) }
    @State private var result: String? = nil
    @State private var played: Bool = false

    struct Box: Identifiable {
        let id = UUID()
        let index: Int
        let won: Bool
        var revealed: Bool
        var picked: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Treat hunt")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(PawlyColors.inkSoft)
                        .tracking(0.5)
                        .textCase(.uppercase)
                    Text(resultText)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(PawlyColors.ink)
                }
                Spacer()
                if played {
                    Button("Replay") {
                        resetGame()
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.6)))
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            HStack(spacing: 10) {
                ForEach(Array(boxes.enumerated()), id: \.element.id) { _, box in
                    Button {
                        pick(box)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(box.revealed ? (box.won ? Color(hex: "#FFE2D4") : Color.white) : Color.white)
                                .frame(height: 76)
                                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                            Text(box.revealed ? (box.won ? "🦴" : "😺") : "📦")
                                .font(.system(size: 32))
                                .offset(y: box.picked ? -4 : 0)
                        }
                    }
                    .disabled(played)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.cardLg, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "#DCEDF5"), Color(hex: "#FFFBF3")], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var resultText: String {
        switch result {
        case "win": return "🎉 You found it! +2 treats"
        case "try": return "Aww, try tomorrow!"
        default: return "Where's the treat?"
        }
    }

    private func pick(_ box: Box) {
        if played { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            boxes = boxes.map { b in
                Box(index: b.index, won: b.won, revealed: true, picked: b.index == box.index)
            }
        }
        let won = boxes[box.index].won
        result = won ? "win" : "try"
        if won {
            treats += 2
            Haptics.success()
        }
        played = true
    }

    private func resetGame() {
        let winner = Int.random(in: 0...2)
        boxes = (0..<3).map { Box(index: $0, won: $0 == winner, revealed: false, picked: false) }
        result = nil
        played = false
    }
}

// MARK: - Pet Profile Components

struct PBGStatCell: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color
    var border: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if border {
                Divider()
                    .frame(width: 1)
                    .background(PawlyColors.borderSoft)
            }
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(tint)
                }
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(PawlyColors.ink)
                Text(label.uppercased())
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct PBGBadgeCard: View {
    let label: String
    let desc: String
    let icon: String
    let tone: Int
    let earnedDate: String

    private var cardTone: PawlyColors.CardTone {
        PawlyColors.CardTone(rawValue: tone % 7) ?? .peach
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(cardTone.tint)
            }
            Text(label)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(PawlyColors.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(desc)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text("EARNED \(earnedDate)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(cardTone.tint)
                .tracking(0.5)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(cardTone.bg)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

struct PBGBadgeProgress: View {
    let label: String
    let desc: String
    let icon: String
    let tone: Int
    let prog: Int
    let total: Int

    private var cardTone: PawlyColors.CardTone {
        PawlyColors.CardTone(rawValue: tone % 7) ?? .sage
    }

    private var pct: Double {
        Double(prog) / Double(total) * 100
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(cardTone.bg.opacity(0.7))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(cardTone.tint.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(PawlyColors.ink)
                    Spacer()
                    Text("\(prog)/\(total)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(cardTone.tint)
                }
                PBCProgressBar(value: pct, color: cardTone.tint, background: Color.white.opacity(0.6))
                Text(desc)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Vault Components

struct PBGVaultCategoryCard: View {
    let label: String
    let icon: String
    let tone: Int
    let count: Int

    private var cardTone: PawlyColors.CardTone {
        PawlyColors.CardTone(rawValue: tone % 7) ?? .peach
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(cardTone.tint)
            }
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PawlyColors.ink)
                .lineLimit(1)
            Text("\(count) document\(count == 1 ? "" : "s")")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PawlyColors.inkSoft)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(cardTone.bg)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

struct PBGDocRow: View {
    let name: String
    let from: String
    let date: String
    let size: String
    let icon: String
    let tone: Int

    private var cardTone: PawlyColors.CardTone {
        PawlyColors.CardTone(rawValue: tone % 7) ?? .sage
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardTone.bg)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(cardTone.tint)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PawlyColors.ink)
                    .lineLimit(1)
                Text(from)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .lineLimit(1)
                Text("\(date) • \(size)")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(PawlyColors.inkMuted)
                    .lineLimit(1)
            }

            Spacer()

            Button { } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                    .foregroundStyle(PawlyColors.inkSoft)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "#F5EEDF"))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}
