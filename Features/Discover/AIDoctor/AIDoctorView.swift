import SwiftUI

/// AI Doctor chat — Groq-powered triage with offline keyword fallback.
/// Input bar is sticky at bottom (outside ScrollView) so keyboard doesn't push it away.
struct AIDoctorView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore

    @State private var prompt: String = ""
    @State private var history: [TriageResponse] = []
    @State private var showFirstUse = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isPromptFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?

    private var activePet: PetDTO? {
        dataStore.pets.first(where: { $0.id == petContext.activePetID }) ?? dataStore.pets.first
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        disclaimer

                        if showFirstUse {
                            firstUseCard
                        }

                        if let errorMessage {
                            errorBanner(errorMessage)
                        }

                        ForEach(history) { r in
                            TriageResponseCard(response: r)
                        }

                        if isLoading {
                            loadingIndicator
                        }

                        // Bottom spacer so first message isn't under composer
                        Color.clear.frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)
                    .padding(.bottom, Spacing.s)
                }
                .background(PawlyColors.cream)
                .onAppear { scrollProxy = proxy }
                .onChange(of: history.count) { _, _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            composer
        }
        .background(PawlyColors.cream.ignoresSafeArea())
        .navigationTitle("AI Doctor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PawlyColors.cream, for: .navigationBar)
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(PawlyColors.forest)
            Text("Pawly's AI Doctor is a triage helper, not a real vet. Always consult a professional for anything urgent.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PawlyColors.slate)
        }
        .padding(Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .fill(PawlyColors.forestLight)
        )
    }

    // MARK: - First use card

    private var firstUseCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("How to use")
                .font(PawlyFont.headingMedium)
                .foregroundStyle(PawlyColors.ink)
            Text("Describe what you've observed. Include timing and anything unusual.")
                .font(PawlyFont.bodyMedium)
                .foregroundStyle(PawlyColors.slate)
            HStack(spacing: 6) {
                ExampleChip("My cat vomited twice today")      { prompt = $0 }
                ExampleChip("Scratching behind ears a lot")   { prompt = $0 }
            }
            .padding(.top, 4)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { showFirstUse = false }
            } label: {
                Text("Got it")
                    .font(PawlyFont.caption)
                    .foregroundStyle(PawlyColors.forest)
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
                .stroke(PawlyColors.sand.opacity(0.4), lineWidth: 0.75)
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(PawlyColors.alert)
            Text(message)
                .font(PawlyFont.caption)
                .foregroundStyle(PawlyColors.alert)
            Spacer()
        }
        .padding(Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .fill(PawlyColors.alert.opacity(0.1))
        )
    }

    private var loadingIndicator: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                ProgressView()
                    .tint(PawlyColors.forest)
                Text("Thinking...")
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)
            }
            .padding(.vertical, Spacing.m)
            Spacer()
        }
    }

    // MARK: - Composer (sticky bottom, outside ScrollView)

    private var composer: some View {
        VStack(spacing: 0) {
            Divider()
                .background(PawlyColors.sand.opacity(0.5))

            HStack(spacing: Spacing.s) {
                TextField("Ask about \(activePet?.name ?? "your pet")...", text: $prompt)
                    .font(PawlyFont.bodyMedium)
                    .focused($isPromptFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                            .fill(PawlyColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                            .stroke(PawlyColors.sand.opacity(0.6), lineWidth: 0.75)
                    )

                Button {
                    ask()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(prompt.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? PawlyColors.sand
                                      : PawlyColors.forest)
                        )
                }
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.s)
            .background(PawlyColors.cream)
        }
    }

    private func ask() {
        let text = prompt.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        Haptics.light()
        isPromptFocused = false
        isLoading = true
        errorMessage = nil
        let capturedPrompt = text
        prompt = ""

        Task {
            let response = await GroqService.respond(
                to: capturedPrompt,
                petName: activePet?.name ?? "your pet"
            )
            withAnimation(.easeInOut(duration: 0.3)) {
                history.insert(response, at: 0)
                isLoading = false
            }
        }
    }
}

// MARK: - Example Chip

struct ExampleChip: View {
    let text: String
    var onTap: (String) -> Void

    init(_ text: String, onTap: @escaping (String) -> Void) {
        self.text = text; self.onTap = onTap
    }

    var body: some View {
        Button { onTap(text) } label: {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(PawlyColors.surface)
                )
                .overlay(
                    Capsule().stroke(PawlyColors.sand.opacity(0.6), lineWidth: 0.75)
                )
                .foregroundStyle(PawlyColors.ink)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Triage Response Card

struct TriageResponseCard: View {
    let response: TriageResponse

    private var urgencyColor: Color {
        switch response.urgency {
        case .watchAtHome:  return PawlyColors.sage
        case .vetWithin24h: return PawlyColors.peach
        case .vetNow:       return PawlyColors.alert
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            // User's question
            HStack(alignment: .top, spacing: Spacing.xs) {
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(PawlyColors.slate)
                Text(response.userPrompt)
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.slate)
                    .lineLimit(3)
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    .fill(PawlyColors.sand.opacity(0.2))
            )

            // AI response
            VStack(alignment: .leading, spacing: Spacing.s) {
                // Urgency badge + confidence
                HStack {
                    Text(response.urgency.displayValue)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(urgencyColor.opacity(0.15)))
                        .foregroundStyle(urgencyColor)
                    Spacer()
                    ConfidenceBadge(level: response.confidence)
                }

                section("What might be happening", items: response.whatMightBeHappening, color: urgencyColor)
                section("What you can do right now", items: response.whatYouCanDoNow, color: urgencyColor)
                section("When to escalate", items: response.whenToEscalate, color: urgencyColor)

                Button {
                    Haptics.medium()
                } label: {
                    Label("Book a vet appointment", systemImage: "calendar.badge.clock")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.pawlyPrimary)
                .padding(.top, 4)
            }
            .padding(Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(PawlyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(urgencyColor.opacity(0.25), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func section(_ title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(PawlyColors.slate)
                .textCase(.uppercase)
            ForEach(items, id: \.self) { i in
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                        .padding(.top, 6)
                    Text(i)
                        .font(PawlyFont.bodyMedium)
                        .foregroundStyle(PawlyColors.ink)
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