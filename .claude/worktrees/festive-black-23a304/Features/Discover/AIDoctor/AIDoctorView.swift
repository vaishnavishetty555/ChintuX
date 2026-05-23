import SwiftUI

/// PawMD — real-time pet health consultation powered by Groq.
/// Feels like a clinical consultation, not a chatbot. Multi-turn conversation.
struct AIDoctorView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var tabBarVisibility: TabBarVisibility

    @State private var prompt: String = ""
    @State private var messages: [DoctorMessage] = []
    @State private var isLoading = false
    @FocusState private var isPromptFocused: Bool

    private var activePet: PetDTO? {
        dataStore.pets.first(where: { $0.id == petContext.activePetID }) ?? dataStore.pets.first
    }

    private var petContextString: String {
        guard let pet = activePet else { return "your pet" }
        var parts: [String] = ["\(pet.name) is a \(pet.speciesRaw.lowercased())"]
        if let dob = pet.dateOfBirth {
            let years = Calendar.current.dateComponents([.year], from: dob, to: .now).year ?? 0
            if years > 0 { parts.append("\(years) year\(years == 1 ? "" : "s") old") }
        }
        if let kg = pet.weightKg {
            parts.append("weighing \(String(format: "%.1f", kg)) kg")
        }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.m) {
                        ForEach(messages) { msg in
                            messageView(msg).id(msg.id)
                        }

                        if isLoading {
                            thinkingView.id("loading")
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.m)
                    .padding(.bottom, Spacing.m)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    withAnimation(Motion.softEaseOut) { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                .onChange(of: isLoading) { _, loading in
                    if loading {
                        withAnimation(Motion.softEaseOut) { proxy.scrollTo("loading", anchor: .bottom) }
                    }
                }
            }
            .background(PawlyColors.canvas.ignoresSafeArea())

            composer
        }
        .navigationTitle("PawMD")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PawlyColors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            tabBarVisibility.hide()
            if messages.isEmpty, let pet = activePet {
                let opening = "Hey! Good to have you here. I'm Dr. Ruff — what's going on with \(pet.name) today? Tell me as much as you can."
                messages = [DoctorMessage(kind: .doctor(DoctorResponse.greeting(opening)))]
            }
        }
        .onDisappear { tabBarVisibility.show() }
    }

    // MARK: - Welcome Header

    // MARK: - Message View

    @ViewBuilder
    private func messageView(_ msg: DoctorMessage) -> some View {
        switch msg.kind {
        case .user(let text):  userBubble(text)
        case .doctor(let r):   doctorCard(r)
        }
    }

    // MARK: - User Bubble

    private func userBubble(_ text: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack {
                Spacer(minLength: 60)
                Text(text)
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(PawlyColors.navy)
                    )
            }
            Text(Date(), format: .dateTime.hour().minute())
                .font(PawlyFont.captionSmall)
                .foregroundStyle(PawlyColors.slate.opacity(0.6))
                .padding(.trailing, 8)
        }
    }

    // MARK: - Doctor Card

    private func doctorCard(_ response: DoctorResponse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(PawlyColors.navySoft)
                        .frame(width: 32, height: 32)
                    Image(systemName: "stethoscope")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PawlyColors.navy)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Dr. Ruff")
                        .font(PawlyFont.bodyMedium.weight(.semibold))
                        .foregroundStyle(PawlyColors.ink)
                    Text("Senior Veterinary Consultant · PawMD")
                        .font(PawlyFont.captionSmall)
                        .foregroundStyle(PawlyColors.slate)
                }
                Spacer()
                if let u = response.urgency { urgencyBadge(u) }
            }
            .padding(Spacing.m)

            Divider().background(PawlyColors.hairline)

            Text(response.displayText)
                .font(PawlyFont.bodyMedium)
                .foregroundStyle(PawlyColors.ink)
                .lineSpacing(5)
                .padding(Spacing.m)

            if response.urgency == .vetNow || response.urgency == .vetWithin24h {
                escalationBox(response.urgency ?? .vetWithin24h)
            }

            if response.urgency != nil {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(PawlyColors.slate.opacity(0.5))
                    Text("AI-assisted guidance. Not a substitute for a physical vet examination.")
                        .font(PawlyFont.captionSmall)
                        .foregroundStyle(PawlyColors.slate.opacity(0.5))
                }
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(PawlyColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(PawlyColors.hairline, lineWidth: 0.75)
        )
        .shadow(color: PawlyColors.shadowWarm, radius: 12, x: 0, y: 4)
    }

    private func urgencyBadge(_ urgency: DoctorUrgency) -> some View {
        let (color, icon, text): (Color, String, String) = switch urgency {
        case .vetNow:       (PawlyColors.alert, "exclamationmark.triangle.fill", "Urgent")
        case .vetWithin24h: (PawlyColors.amber,  "clock.fill",                   "See Vet")
        case .watchAtHome:  (PawlyColors.sage,   "checkmark",                    "Monitor")
        }

        return HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .semibold))
            Text(text).font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.15)))
    }

    private func escalationBox(_ urgency: DoctorUrgency) -> some View {
        let color = urgency == .vetNow ? PawlyColors.alert : PawlyColors.amber
        let message = urgency == .vetNow
            ? "This sounds like a medical emergency. Please go to a vet clinic now."
            : "Please schedule a vet visit within 24 hours if symptoms persist."

        return HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(message)
                .font(PawlyFont.bodyMedium)
                .foregroundStyle(color)
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 0.75)
        )
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.m)
    }

    // MARK: - Thinking View

    private var thinkingView: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(PawlyColors.navySoft)
                    .frame(width: 32, height: 32)
                Image(systemName: "stethoscope")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PawlyColors.navy)
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(PawlyColors.slate.opacity(0.4))
                        .frame(width: 7, height: 7)
                        .scaleEffect(isLoading ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.15),
                            value: isLoading
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(PawlyColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(PawlyColors.hairline, lineWidth: 0.75)
            )

            Spacer(minLength: 0)
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(PawlyColors.divider)
                .frame(height: 0.5)

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Describe symptoms…", text: $prompt, axis: .vertical)
                    .font(PawlyFont.bodyMedium)
                    .foregroundStyle(PawlyColors.ink)
                    .lineLimit(1...5)
                    .focused($isPromptFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(PawlyColors.canvas)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(PawlyColors.hairline, lineWidth: 0.75)
                    )
                    .onSubmit { send() }

                Button { send() } label: {
                    Image(systemName: isLoading ? "stop.fill" : "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(canSend ? PawlyColors.navy : PawlyColors.slate.opacity(0.35)))
                }
                .disabled(!canSend)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(PawlyColors.surface)
        }
    }

    private var canSend: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    // MARK: - Send

    private func send() {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        Haptics.light()
        prompt = ""

        withAnimation(Motion.softEaseOut) {
            messages.append(DoctorMessage(kind: .user(text)))
        }

        isLoading = true

        Task {
            // Build history from real API turns (skip the local opening greeting)
            let history: [(role: String, content: String)] = messages.dropLast().compactMap { msg in
                switch msg.kind {
                case .user(let t):
                    return ("user", t)
                case .doctor(let r):
                    guard !r.rawText.isEmpty else { return nil }  // skip local greeting
                    return ("assistant", r.rawText)
                }
            }

            let response = await GroqService.respond(
                to: text,
                petName: activePet?.name ?? "your pet",
                petContext: petContextString,
                history: history
            )

            let doctorMsg = DoctorMessage(kind: .doctor(DoctorResponse(from: response)))

            await MainActor.run {
                withAnimation(Motion.softEaseOut) {
                    messages.append(doctorMsg)
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Doctor Models

struct DoctorMessage: Identifiable {
    enum Kind {
        case user(String)
        case doctor(DoctorResponse)
    }
    let id = UUID()
    let kind: Kind
}

struct DoctorResponse {
    let displayText: String   // cleaned text shown in the bubble
    let urgency: DoctorUrgency?  // nil = no badge (greeting / short reply)
    let rawText: String       // full original text for multi-turn history

    // Local opening greeting — not sent to the API
    static func greeting(_ text: String) -> DoctorResponse {
        DoctorResponse(displayText: text, urgency: nil, rawText: "")
    }

    init(from triage: TriageResponse) {
        self.rawText = triage.freeText
        let cleaned = triage.freeText
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("[URGENCY:") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.displayText = cleaned

        switch triage.urgency {
        case .watchAtHome:  self.urgency = .watchAtHome
        case .vetWithin24h: self.urgency = .vetWithin24h
        case .vetNow:       self.urgency = .vetNow
        case nil:           self.urgency = nil
        }
    }

    private init(displayText: String, urgency: DoctorUrgency?, rawText: String) {
        self.displayText = displayText
        self.urgency = urgency
        self.rawText = rawText
    }
}

enum DoctorUrgency { case watchAtHome, vetWithin24h, vetNow }

// MARK: - Preview

#Preview("PawMD") {
    NavigationStack { AIDoctorView() }
        .environmentObject(PreviewSupport.previewPetContext)
        .environmentObject(DataStore.shared)
        .environmentObject(TabBarVisibility())
}
