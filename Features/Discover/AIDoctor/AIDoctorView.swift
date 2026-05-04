import SwiftUI

/// PRD §6.5 — AI Doctor chat with structured 4-part triage response.
/// Now powered by Groq LLM API with offline keyword fallback.
struct AIDoctorView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore

    @State private var prompt: String = ""
    @State private var history: [TriageResponse] = []
    @State private var showFirstUse = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isPromptFocused: Bool

    private var activePet: PetDTO? {
        dataStore.pets.first(where: { $0.id == petContext.activePetID }) ?? dataStore.pets.first
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    disclaimer

                    if showFirstUse {
                        firstUseCard
                    }

                    if let errorMessage {
                        PawlyCard {
                            HStack(spacing: Spacing.s) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(PawlyColors.alert)
                                Text(errorMessage)
                                    .font(PawlyFont.caption)
                                    .foregroundStyle(PawlyColors.alert)
                                Spacer()
                            }
                        }
                    }

                    ForEach(history) { r in
                        TriageResponseCard(response: r)
                    }

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Asking AI Doctor...")
                                .tint(PawlyColors.forest)
                            Spacer()
                        }
                        .padding(.vertical, Spacing.m)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.m)
            }
            .background(PawlyColors.cream)

            composer
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .navigationTitle("AI Doctor")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var disclaimer: some View {
        PawlyCard {
            HStack(spacing: Spacing.s) {
                Image(systemName: "info.circle.fill").foregroundStyle(PawlyColors.forest)
                Text("Pawly's AI Doctor is a triage helper, not a real vet. Always call a vet for anything urgent or uncertain.")
                    .font(PawlyFont.caption).foregroundStyle(PawlyColors.ink)
            }
        }
        .accessibilityLabel("Disclaimer: Pawly's AI Doctor is a triage helper, not a real vet.")
    }

    private var firstUseCard: some View {
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("How to use")
                    .font(PawlyFont.headingMedium).foregroundStyle(PawlyColors.ink)
                Text("Describe what you've observed in plain words. Include timing and anything unusual.")
                    .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                HStack(spacing: 6) {
                    ExampleChip("My cat vomited twice today") { prompt = $0 }
                    ExampleChip("Scratching behind ears a lot") { prompt = $0 }
                }
                .padding(.top, 4)
                Button {
                    withAnimation(Motion.transition) { showFirstUse = false }
                } label: { Text("Got it").font(PawlyFont.caption).foregroundStyle(PawlyColors.forest) }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 0) {
            Divider().background(PawlyColors.sand)

            HStack(spacing: Spacing.s) {
                TextField("Ask about \(activePet?.name ?? "your pet")...", text: $prompt)
                    .font(PawlyFont.bodyMedium)
                    .focused($isPromptFocused)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                            .fill(PawlyColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                            .stroke(PawlyColors.sand, lineWidth: 1)
                    )

                Button {
                    ask()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(PawlyColors.forest))
                }
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.s)
        }
        .background(PawlyColors.cream)
    }

    private func ask() {
        let text = prompt.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        Haptics.light()
        isPromptFocused = false
        isLoading = true
        errorMessage = nil
        prompt = ""

        Task {
            let response = await GroqService.respond(
                to: text,
                petName: activePet?.name ?? "your pet"
            )
            withAnimation(Motion.transition) {
                history.insert(response, at: 0)
                isLoading = false
            }
        }
    }
}

struct ExampleChip: View {
    let text: String
    var onTap: (String) -> Void

    init(_ text: String, onTap: @escaping (String) -> Void) {
        self.text = text; self.onTap = onTap
    }

    var body: some View {
        Button { onTap(text) } label: {
            Text(text)
                .font(PawlyFont.captionSmall)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(PawlyColors.cream))
                .overlay(Capsule().stroke(PawlyColors.sand, lineWidth: 1))
                .foregroundStyle(PawlyColors.ink)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Triage response card

struct TriageResponseCard: View {
    let response: TriageResponse

    private var urgencyColor: Color {
        switch response.urgency {
        case .watchAtHome:   return PawlyColors.sage
        case .vetWithin24h:  return PawlyColors.peach
        case .vetNow:        return PawlyColors.alert
        }
    }

    var body: some View {
        PawlyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "quote.bubble")
                    Text(response.userPrompt)
                        .font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.slate)
                        .lineLimit(2)
                }

                HStack {
                    Text(response.urgency.displayValue)
                        .font(PawlyFont.caption)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(urgencyColor.opacity(0.2)))
                        .foregroundStyle(urgencyColor)
                    Spacer()
                    ConfidenceBadge(level: response.confidence)
                }

                section("What might be happening", items: response.whatMightBeHappening)
                section("What you can do right now", items: response.whatYouCanDoNow)
                section("When to escalate", items: response.whenToEscalate)

                Button {
                    Haptics.medium()
                } label: {
                    Label("Book a vet", systemImage: "calendar.badge.clock")
                }
                .buttonStyle(.pawlyPrimary)
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(PawlyFont.caption).foregroundStyle(PawlyColors.slate)
            ForEach(items, id: \.self) { i in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundStyle(PawlyColors.slate)
                    Text(i).font(PawlyFont.bodyMedium).foregroundStyle(PawlyColors.ink)
                }
            }
        }
    }
}

#Preview("AI Doctor") {
    NavigationStack { AIDoctorView() }
        .environmentObject(PreviewSupport.previewPetContext)
        .environmentObject(DataStore.shared)
}
