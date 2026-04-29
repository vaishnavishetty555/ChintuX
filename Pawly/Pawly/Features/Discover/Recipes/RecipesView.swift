import SwiftUI

/// PRD §6.7 — Recipes library (stub with vet-reviewed sample recipes).
struct RecipesView: View {
    @State private var species: Species? = nil
    @State private var filter: PetRecipe.Filter? = nil

    private var recipes: [PetRecipe] { PetRecipe.starter }

    private var filtered: [PetRecipe] {
        recipes.filter {
            (species == nil || $0.species.contains(species!))
            && (filter == nil || $0.filters.contains(filter!))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                disclaimer
                filterRow
                ForEach(filtered) { r in
                    NavigationLink(destination: RecipeDetailView(recipe: r)) {
                        RecipeCard(recipe: r)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.m)
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .navigationTitle("Recipes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var disclaimer: some View {
        PawlyCard {
            HStack(spacing: Spacing.s) {
                Image(systemName: "leaf.fill").foregroundStyle(PawlyColors.sage)
                Text("Always check with your vet before changing your pet's diet.")
                    .font(PawlyFont.caption).foregroundStyle(PawlyColors.ink)
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                pill("All species", active: species == nil) { species = nil }
                ForEach(Species.allCases) { s in
                    pill(s.displayName, active: species == s) { species = s }
                }
                Divider().frame(height: 20).padding(.horizontal, 4)
                pill("Any", active: filter == nil) { filter = nil }
                ForEach(PetRecipe.Filter.allCases, id: \.self) { f in
                    pill(f.rawValue.capitalized, active: filter == f) { filter = f }
                }
            }
        }
    }

    @ViewBuilder
    private func pill(_ title: String, active: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(title)
                .font(PawlyFont.captionSmall)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(active ? PawlyColors.forest : PawlyColors.surface))
                .foregroundStyle(active ? .white : PawlyColors.ink)
                .overlay(Capsule().stroke(PawlyColors.sand, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

struct RecipeCard: View {
    let recipe: PetRecipe
    var body: some View {
        PawlyCard {
            HStack(spacing: Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.card).fill(PawlyColors.sage.opacity(0.2))
                    Image(systemName: recipe.symbol).foregroundStyle(PawlyColors.sage).font(.system(size: 24))
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.title).font(PawlyFont.headingMedium).foregroundStyle(PawlyColors.ink)
                    Text(recipe.summary).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text("\(recipe.minutes) min")
                        Text("•").foregroundStyle(PawlyColors.slate)
                        Text(recipe.species.map(\.displayName).joined(separator: ", "))
                    }
                    .font(PawlyFont.captionSmall)
                    .foregroundStyle(PawlyColors.slate)
                }
                Spacer()
            }
        }
    }
}

struct RecipeDetailView: View {
    let recipe: PetRecipe
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                PawlyCard {
                    HStack {
                        Image(systemName: recipe.symbol).font(.system(size: 40)).foregroundStyle(PawlyColors.sage)
                        VStack(alignment: .leading) {
                            Text(recipe.title).font(PawlyFont.displayMedium).foregroundStyle(PawlyColors.ink)
                            Text("\(recipe.minutes) min • \(recipe.species.map(\.displayName).joined(separator: ", "))")
                                .font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                        }
                    }
                }
                PawlyCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ingredients").font(PawlyFont.headingMedium)
                        ForEach(recipe.ingredients, id: \.self) { i in
                            Label(i, systemImage: "leaf")
                                .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
                        }
                    }
                }
                PawlyCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Steps").font(PawlyFont.headingMedium)
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, s in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(i + 1).").font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.forest)
                                Text(s).font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
                            }
                        }
                    }
                }
                if !recipe.avoidList.isEmpty {
                    PawlyCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Avoid").font(PawlyFont.headingMedium)
                            ForEach(recipe.avoidList, id: \.self) { m in
                                Label(m, systemImage: "xmark.octagon")
                                    .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.alert)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.m)
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Static recipe data

struct PetRecipe: Identifiable {
    enum Filter: String, CaseIterable { case puppy, adult, senior, sensitive }
    let id = UUID()
    let title: String
    let summary: String
    let symbol: String
    let minutes: Int
    let species: [Species]
    let filters: [Filter]
    let ingredients: [String]
    let steps: [String]
    let avoidList: [String]

    static let starter: [PetRecipe] = [
        .init(title: "Chicken & rice bowl",
              summary: "Gentle on upset stomachs. Vet-approved bland diet.",
              symbol: "bowl.fill",
              minutes: 25, species: [.dog], filters: [.adult, .sensitive],
              ingredients: ["1 cup boneless chicken breast", "2 cups white rice", "4 cups water", "No salt, no onion, no garlic"],
              steps: ["Boil chicken until fully cooked; shred.",
                      "Cook rice in the chicken broth.",
                      "Mix 1 part chicken to 2 parts rice.",
                      "Cool to room temperature before serving."],
              avoidList: ["Onion and garlic — toxic to dogs.",
                          "Seasonings and salt."]),
        .init(title: "Tuna & pumpkin mash",
              summary: "Moisture-rich meal for picky cats.",
              symbol: "fish.fill",
              minutes: 10, species: [.cat], filters: [.adult],
              ingredients: ["1 can tuna in water (drained)", "2 tbsp plain pumpkin purée", "1 tbsp warm water"],
              steps: ["Mash all ingredients together.",
                      "Serve small portions; refrigerate leftovers up to 24h."],
              avoidList: ["Tuna in oil or brine.",
                          "Any onion/garlic."]),
        .init(title: "Puppy growth bowl",
              summary: "High-protein, balanced macros for growing pups.",
              symbol: "pawprint.fill",
              minutes: 35, species: [.dog], filters: [.puppy],
              ingredients: ["1 cup ground turkey", "½ cup cooked quinoa", "¼ cup diced carrots", "1 tbsp plain yogurt"],
              steps: ["Cook turkey thoroughly; drain fat.",
                      "Steam carrots until soft.",
                      "Combine with quinoa and yogurt.",
                      "Serve at body temperature."],
              avoidList: ["Raw meat for puppies.",
                          "Dairy beyond a small spoon of plain yogurt."]),
        .init(title: "Senior joint supper",
              summary: "Soft texture and omega-3 fats for older pets.",
              symbol: "heart.fill",
              minutes: 30, species: [.dog, .cat], filters: [.senior],
              ingredients: ["1 cup cooked salmon (deboned)", "½ cup sweet potato", "1 tsp flaxseed oil"],
              steps: ["Steam and mash the sweet potato.",
                      "Flake the salmon into the mash.",
                      "Drizzle flaxseed oil; mix and serve warm."],
              avoidList: ["Raw salmon — parasite risk.",
                          "Any added salt."]),
        .init(title: "Rabbit veggie salad",
              summary: "Daily fresh greens to balance hay.",
              symbol: "leaf.fill",
              minutes: 5, species: [.rabbit], filters: [.adult],
              ingredients: ["Romaine lettuce", "Cilantro", "Bell pepper (no seeds)", "A few mint leaves"],
              steps: ["Wash all greens thoroughly.",
                      "Chop into bite-sized pieces.",
                      "Serve at room temperature alongside hay."],
              avoidList: ["Iceberg lettuce — low nutrients.",
                          "Onion family — toxic."]),
    ]
}

#Preview("Recipes") {
    NavigationStack { RecipesView() }
}
