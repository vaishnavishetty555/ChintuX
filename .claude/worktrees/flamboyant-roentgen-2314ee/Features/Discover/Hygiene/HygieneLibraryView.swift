import SwiftUI

/// PRD §6.6 — DIY Hygiene library (stub with 6 hand-crafted guides).
struct HygieneLibraryView: View {
    @State private var species: Species? = nil
    @State private var difficulty: HygieneGuide.Difficulty? = nil

    private var guides: [HygieneGuide] { HygieneGuide.starter }

    private var filtered: [HygieneGuide] {
        guides.filter {
            (species == nil || $0.species.contains(species!))
            && (difficulty == nil || $0.difficulty == difficulty)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                filterRow
                ForEach(filtered) { g in
                    NavigationLink(destination: HygieneGuideView(guide: g)) {
                        HygieneCard(guide: g)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.m)
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .navigationTitle("DIY Hygiene")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                pill("All species", active: species == nil) { species = nil }
                ForEach(Species.allCases) { s in
                    pill(s.displayName, active: species == s) { species = s }
                }
                Divider().frame(height: 20).padding(.horizontal, 4)
                pill("Any difficulty", active: difficulty == nil) { difficulty = nil }
                ForEach(HygieneGuide.Difficulty.allCases, id: \.self) { d in
                    pill(d.rawValue.capitalized, active: difficulty == d) { difficulty = d }
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

struct HygieneCard: View {
    let guide: HygieneGuide
    var body: some View {
        PawlyCard {
            HStack(spacing: Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.card).fill(PawlyColors.peach.opacity(0.2))
                    Image(systemName: guide.symbol).foregroundStyle(PawlyColors.peach).font(.system(size: 24))
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 2) {
                    Text(guide.title).font(PawlyFont.headingMedium).foregroundStyle(PawlyColors.ink)
                    Text(guide.summary).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text(guide.minutes == 1 ? "1 min" : "\(guide.minutes) min")
                        Text("•").foregroundStyle(PawlyColors.slate)
                        Text(guide.difficulty.rawValue.capitalized)
                    }
                    .font(PawlyFont.captionSmall)
                    .foregroundStyle(PawlyColors.slate)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Guide Detail

struct HygieneGuideView: View {
    let guide: HygieneGuide
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                PawlyCard {
                    HStack {
                        Image(systemName: guide.symbol).font(.system(size: 40)).foregroundStyle(PawlyColors.peach)
                        VStack(alignment: .leading) {
                            Text(guide.title).font(PawlyFont.displayMedium).foregroundStyle(PawlyColors.ink)
                            Text("\(guide.minutes) min • \(guide.difficulty.rawValue.capitalized)")
                                .font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
                        }
                    }
                }
                PawlyCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("You will need").font(PawlyFont.headingMedium)
                        ForEach(guide.materials, id: \.self) { m in
                            Label(m, systemImage: "checkmark.circle")
                                .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
                        }
                    }
                }
                PawlyCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Steps").font(PawlyFont.headingMedium)
                        ForEach(Array(guide.steps.enumerated()), id: \.offset) { i, s in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(i + 1).").font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.forest)
                                Text(s).font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
                            }
                        }
                    }
                }
                PawlyCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Common mistakes").font(PawlyFont.headingMedium)
                        ForEach(guide.commonMistakes, id: \.self) { m in
                            Label(m, systemImage: "exclamationmark.triangle")
                                .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.alert)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.m)
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .navigationTitle(guide.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Static guide data

struct HygieneGuide: Identifiable {
    enum Difficulty: String, CaseIterable { case easy, medium, hard }
    let id = UUID()
    let title: String
    let summary: String
    let symbol: String
    let minutes: Int
    let difficulty: Difficulty
    let species: [Species]
    let materials: [String]
    let steps: [String]
    let commonMistakes: [String]

    static let starter: [HygieneGuide] = [
        .init(title: "Brushing teeth",
              summary: "Keep plaque and tartar at bay with a quick daily habit.",
              symbol: "mouth.fill",
              minutes: 3, difficulty: .easy, species: [.dog, .cat],
              materials: ["Pet toothbrush", "Enzyme pet toothpaste", "Soft towel"],
              steps: ["Let them sniff the toothpaste.",
                      "Lift the lip gently; brush the outer surfaces only.",
                      "Work in small circles, back to front.",
                      "Reward with a calm cuddle."],
              commonMistakes: ["Using human toothpaste — it's toxic.",
                               "Forcing an open mouth — causes aversion."]),
        .init(title: "Nail trimming",
              summary: "A quick trim keeps paws healthy and the home scratch-free.",
              symbol: "scissors",
              minutes: 5, difficulty: .medium, species: [.dog, .cat, .rabbit],
              materials: ["Pet nail clipper", "Styptic powder", "A favorite treat"],
              steps: ["Identify the quick — the pink part.",
                      "Clip only the clear tip, well before the quick.",
                      "Go nail by nail, pausing to reward."],
              commonMistakes: ["Clipping too close and causing bleeding.",
                               "Using dull clippers that crush the nail."]),
        .init(title: "Ear cleaning",
              summary: "Weekly wipe-down to prevent infections.",
              symbol: "ear",
              minutes: 4, difficulty: .easy, species: [.dog, .cat],
              materials: ["Vet-approved ear cleaner", "Cotton pads"],
              steps: ["Squeeze cleaner onto a cotton pad.",
                      "Gently wipe the visible part of the outer ear.",
                      "Do not insert anything into the ear canal."],
              commonMistakes: ["Using cotton swabs deep in the ear.",
                               "Cleaning too frequently — strips natural oils."]),
        .init(title: "Bath basics",
              summary: "When and how to bathe without drying their skin.",
              symbol: "drop.fill",
              minutes: 20, difficulty: .medium, species: [.dog],
              materials: ["Pet shampoo", "Non-slip mat", "Two towels"],
              steps: ["Brush first to remove loose hair.",
                      "Wet from the neck down; avoid the face.",
                      "Lather, rinse thoroughly, towel-dry.",
                      "Keep warm and draft-free until dry."],
              commonMistakes: ["Bathing too often (skin dryness).",
                               "Using human shampoo."]),
        .init(title: "Litter box hygiene",
              summary: "A clean box keeps cats happy and your home odor-free.",
              symbol: "tray.fill",
              minutes: 5, difficulty: .easy, species: [.cat],
              materials: ["Scoop", "Unscented clumping litter", "Mat"],
              steps: ["Scoop clumps daily.",
                      "Top up litter to maintain 5–7 cm depth.",
                      "Wash the box every 2 weeks with mild soap."],
              commonMistakes: ["Strongly scented litters — many cats avoid them.",
                               "Skipping the weekly full wash."]),
        .init(title: "Cage cleaning",
              summary: "A weekly refresh for happy birds.",
              symbol: "house.fill",
              minutes: 15, difficulty: .easy, species: [.bird],
              materials: ["Mild soap", "Warm water", "Fresh liner paper"],
              steps: ["Move the bird to a safe travel cage.",
                      "Discard old paper and leftover food.",
                      "Wash and rinse all perches and bowls.",
                      "Dry fully before returning the bird."],
              commonMistakes: ["Using strong disinfectants.",
                               "Returning perches while still damp."]),
    ]
}
