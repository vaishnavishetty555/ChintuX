import SwiftUI

/// Discover tab — editorial layout. Strong visual hierarchy,
/// generous whitespace, restrained color usage.
struct DiscoverView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Discover")
                            .font(PawlyFont.displayLarge)
                            .foregroundStyle(PawlyColors.ink)
                        Text("Gentle help for everyday pet care.")
                            .font(PawlyFont.bodyLarge)
                            .foregroundStyle(PawlyColors.slate)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)
                    .padding(.bottom, Spacing.xl)

                    // PawMD — hero treatment
                    NavigationLink(destination: AIDoctorView()) {
                        PawMDHeroCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xl)

                    // Section
                    Text("More for your pet")
                        .font(PawlyFont.overline)
                        .foregroundStyle(PawlyColors.slate)
                        .textCase(.uppercase)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.m)

                    VStack(spacing: 12) {
                        NavigationLink(destination: HygieneLibraryView()) {
                            DiscoverRow(
                                title: "DIY Hygiene",
                                subtitle: "Grooming, dental, nails and more",
                                symbol: "sparkles",
                                tint: PawlyColors.peach
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: RecipesView()) {
                            DiscoverRow(
                                title: "Recipes",
                                subtitle: "Vet-reviewed home-cooked meals",
                                symbol: "fork.knife",
                                tint: PawlyColors.sage
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)

                    Color.clear.frame(height: Spacing.xxl)
                }
            }
            .scrollIndicators(.hidden)
            .background(PawlyColors.canvas.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

// MARK: - PawMD Hero Card

struct PawMDHeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [PawlyColors.navy, PawlyColors.navy.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: "stethoscope")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("Ask Chintu Ji")
                            .font(PawlyFont.headingLarge)
                            .foregroundStyle(PawlyColors.ink)
                        Text("BETA")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(PawlyColors.navySoft))
                            .foregroundStyle(PawlyColors.navy)
                    }
                    Text("Real vet consult, anytime")
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.slate)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                pillFeature(icon: "bolt.fill",            text: "Instant")
                pillFeature(icon: "bubble.left.and.bubble.right", text: "Conversational")
                pillFeature(icon: "globe",                text: "Free")
            }

            HStack {
                Text("Start a consultation")
                    .font(PawlyFont.label)
                    .foregroundStyle(PawlyColors.navy)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PawlyColors.navy)
            }
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(PawlyColors.navy.opacity(0.12), lineWidth: 0.75)
        )
    }

    private func pillFeature(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(PawlyColors.slate)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(PawlyColors.canvas))
        .overlay(Capsule().stroke(PawlyColors.hairline, lineWidth: 0.5))
    }
}

// Keep old name as alias so any other call sites don't break
typealias AIDoctorHeroCard = PawMDHeroCard

// MARK: - Row Card

struct DiscoverRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PawlyFont.headingSmall)
                    .foregroundStyle(PawlyColors.ink)
                Text(subtitle)
                    .font(PawlyFont.captionSmall)
                    .foregroundStyle(PawlyColors.slate)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PawlyColors.slate.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(PawlyColors.hairline, lineWidth: 0.75)
        )
    }
}
