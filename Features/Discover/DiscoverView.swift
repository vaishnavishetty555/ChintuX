import SwiftUI

/// Discover tab: landing page with three entries.
struct DiscoverView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("Discover")
                        .font(PawlyFont.displayMedium)
                        .foregroundStyle(PawlyColors.ink)
                    Text("Gentle help for everyday pet care.")
                        .font(PawlyFont.bodyLarge)
                        .foregroundStyle(PawlyColors.slate)

                    NavigationLink(destination: AIDoctorView()) {
                        DiscoverCard(
                            title: "AI Doctor",
                            subtitle: "Triage assistant for odd moments. Not a diagnostician.",
                            symbol: "stethoscope",
                            tint: PawlyColors.forest
                        )
                    }.buttonStyle(.plain)

                    NavigationLink(destination: HygieneLibraryView()) {
                        DiscoverCard(
                            title: "DIY Hygiene",
                            subtitle: "How-to guides for grooming, dental, nails and more.",
                            symbol: "sparkles",
                            tint: PawlyColors.peach
                        )
                    }.buttonStyle(.plain)

                    NavigationLink(destination: RecipesView()) {
                        DiscoverCard(
                            title: "Recipes",
                            subtitle: "Vet-reviewed home-cooked meals.",
                            symbol: "fork.knife",
                            tint: PawlyColors.sage
                        )
                    }.buttonStyle(.plain)

                    NavigationLink(destination: VaultHomeView(pet: nil)) {
                        DiscoverCard(
                            title: "Pet Vault",
                            subtitle: "Encrypted storage for certificates, bills, and travel papers.",
                            symbol: "lock.shield.fill",
                            tint: PawlyColors.forest
                        )
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.m)
            }
            .background(PawlyColors.cream.ignoresSafeArea())
        }
    }
}

struct DiscoverCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        PawlyCard {
            HStack(spacing: Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.card).fill(tint.opacity(0.15))
                    Image(systemName: symbol).font(.system(size: 22)).foregroundStyle(tint)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(PawlyFont.headingMedium).foregroundStyle(PawlyColors.ink)
                    Text(subtitle).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(PawlyColors.slate)
            }
        }
    }
}
