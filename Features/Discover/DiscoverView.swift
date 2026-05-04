import SwiftUI

/// Discover tab — clean entry point to AI Doctor, Hygiene, Recipes, Vault.
struct DiscoverView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
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

                    // AI Doctor — primary feature
                    NavigationLink(destination: AIDoctorView()) {
                        DiscoverHeroCard(
                            title: "AI Doctor",
                            subtitle: "Describe symptoms, get a triage assessment instantly.",
                            symbol: "stethoscope",
                            tint: PawlyColors.forest
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.screenHorizontal)

                    // Secondary features grid
                    VStack(spacing: 10) {
                        NavigationLink(destination: HygieneLibraryView()) {
                            DiscoverRow(
                                title: "DIY Hygiene",
                                subtitle: "Grooming, dental, nails and more.",
                                symbol: "sparkles",
                                tint: PawlyColors.peach
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: RecipesView()) {
                            DiscoverRow(
                                title: "Recipes",
                                subtitle: "Vet-reviewed home-cooked meals.",
                                symbol: "fork.knife",
                                tint: PawlyColors.sage
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: VaultHomeView(pet: nil)) {
                            DiscoverRow(
                                title: "Pet Vault",
                                subtitle: "Encrypted certificates, bills, travel papers.",
                                symbol: "lock.shield.fill",
                                tint: PawlyColors.forest
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .background(PawlyColors.cream.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Hero Card

struct DiscoverHeroCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(PawlyFont.headingLarge)
                    .foregroundStyle(PawlyColors.ink)
                Text(subtitle)
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PawlyColors.sand)
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(tint.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
    }
}

// MARK: - Row Card

struct DiscoverRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(PawlyFont.headingMedium)
                    .foregroundStyle(PawlyColors.ink)
                Text(subtitle)
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.slate)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PawlyColors.sand)
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(PawlyColors.sand.opacity(0.4), lineWidth: 0.75)
        )
    }
}