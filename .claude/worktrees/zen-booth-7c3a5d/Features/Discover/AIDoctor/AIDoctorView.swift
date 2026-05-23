import SwiftUI

// MARK: - Chat Session Persistence

struct StoredMessage: Codable, Identifiable {
    let id: UUID
    let isUser: Bool
    let displayText: String
    let rawText: String
    let urgencyRaw: String?
    let createdAt: Date

    init(id: UUID = UUID(), isUser: Bool, displayText: String, rawText: String = "", urgencyRaw: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.isUser = isUser
        self.displayText = displayText
        self.rawText = rawText
        self.urgencyRaw = urgencyRaw
        self.createdAt = createdAt
    }
}

struct ChatSession: Codable, Identifiable {
    let id: UUID
    var title: String
    var messages: [StoredMessage]
    let createdAt: Date
    var updatedAt: Date
}

@MainActor
final class ChatSessionStore: ObservableObject {
    static let shared = ChatSessionStore()

    @Published private(set) var sessions: [ChatSession] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("pawmd_sessions.json")
    }()

    init() { load() }

    func createSession(firstUserMessage: String) -> UUID {
        let id = UUID()
        let title = String(firstUserMessage.prefix(50))
        let session = ChatSession(id: id, title: title, messages: [], createdAt: .now, updatedAt: .now)
        sessions.insert(session, at: 0)
        save()
        return id
    }

    func append(_ message: StoredMessage, to sessionId: UUID) {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        sessions[idx].messages.append(message)
        sessions[idx].updatedAt = .now
        let updated = sessions.remove(at: idx)
        sessions.insert(updated, at: 0)
        save()
    }

    func delete(sessionId: UUID) {
        sessions.removeAll { $0.id == sessionId }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) else { return }
        sessions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - AI Doctor View

/// PawMD — real-time pet health consultation powered by Groq.
/// Multi-turn conversation. All registered pets in context. Sessions persist.
struct AIDoctorView: View {
    @EnvironmentObject var petContext: PetContextStore
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var tabBarVisibility: TabBarVisibility
    @ObservedObject private var sessionStore = ChatSessionStore.shared

    @State private var prompt: String = ""
    @State private var messages: [DoctorMessage] = []
    @State private var isLoading = false
    @State private var currentSessionId: UUID? = nil
    @State private var showingHistory = false
    @FocusState private var isPromptFocused: Bool

    private var activePets: [PetDTO] {
        dataStore.pets.filter { $0.statusRaw == "active" }
    }

    private var allPetsContextString: String {
        guard !activePets.isEmpty else { return "no pets registered yet" }
        return activePets.map { pet -> String in
            var parts: [String] = ["\(pet.name) (\(pet.speciesRaw.lowercased())"]
            if !pet.breed.isEmpty { parts[0] += ", \(pet.breed)" }
            parts[0] += ")"
            if let dob = pet.dateOfBirth {
                let years = Calendar.current.dateComponents([.year], from: dob, to: .now).year ?? 0
                let months = Calendar.current.dateComponents([.month], from: dob, to: .now).month ?? 0
                if years > 0 { parts.append("\(years)yr old") }
                else if months > 0 { parts.append("\(months)mo old") }
            }
            if let kg = pet.weightKg { parts.append("\(String(format: "%.1f", kg))kg") }
            if !pet.allergiesText.isEmpty { parts.append("allergies: \(pet.allergiesText)") }
            if !pet.ongoingConditionsText.isEmpty { parts.append("conditions: \(pet.ongoingConditionsText)") }
            return parts.joined(separator: ", ")
        }.joined(separator: "\n- ")
    }

    private var petNamesDisplay: String {
        let names = activePets.map(\.name)
        if names.isEmpty { return "your pets" }
        if names.count == 1 { return names[0] }
        return names.dropLast().joined(separator: ", ") + " & " + (names.last ?? "")
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
        .navigationTitle("Chintu Ji")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PawlyColors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                }
                .tint(PawlyColors.navy)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    startNewChat()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .medium))
                }
                .tint(PawlyColors.navy)
            }
        }
        .onAppear {
            tabBarVisibility.hide()
            if messages.isEmpty {
                showGreeting()
            }
        }
        .onDisappear { tabBarVisibility.show() }
        .sheet(isPresented: $showingHistory) {
            ChatHistoryView { session in
                loadSession(session)
            }
        }
    }

    // MARK: - Session Management

    private func showGreeting() {
        let opening: String
        if activePets.isEmpty {
            opening = "Hey! I'm Chintu Ji — add a pet profile first and I'll be able to give you personalised advice."
        } else {
            opening = "Hey! Good to have you here. I'm Chintu Ji — I've got profiles for \(petNamesDisplay). Ask me anything about any of them, or just describe what you're seeing."
        }
        messages = [DoctorMessage(kind: .doctor(DoctorResponse.greeting(opening)))]
    }

    private func startNewChat() {
        currentSessionId = nil
        messages = []
        prompt = ""
        showGreeting()
    }

    private func loadSession(_ session: ChatSession) {
        currentSessionId = session.id
        messages = session.messages.map { stored in
            if stored.isUser {
                return DoctorMessage(kind: .user(stored.displayText))
            } else {
                let urgency: DoctorUrgency? = stored.urgencyRaw.flatMap { raw in
                    switch raw {
                    case "watchAtHome": return .watchAtHome
                    case "vetWithin24h": return .vetWithin24h
                    case "vetNow": return .vetNow
                    default: return nil
                    }
                }
                let dr = DoctorResponse(displayText: stored.displayText, urgency: urgency, rawText: stored.rawText)
                return DoctorMessage(kind: .doctor(dr))
            }
        }
    }

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
                    Text("Chintu Ji")
                        .font(PawlyFont.bodyMedium.weight(.semibold))
                        .foregroundStyle(PawlyColors.ink)
                    Text("Your Pet's Personal Vet")
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

        // Create session on first real user message
        let sessionId: UUID
        if let existing = currentSessionId {
            sessionId = existing
        } else {
            sessionId = sessionStore.createSession(firstUserMessage: text)
            currentSessionId = sessionId
        }
        sessionStore.append(StoredMessage(isUser: true, displayText: text, rawText: text), to: sessionId)

        Task {
            let history: [(role: String, content: String)] = messages.dropLast().compactMap { msg in
                switch msg.kind {
                case .user(let t):
                    return ("user", t)
                case .doctor(let r):
                    guard !r.rawText.isEmpty else { return nil }
                    return ("assistant", r.rawText)
                }
            }

            let response = await GroqService.respond(
                to: text,
                petName: petNamesDisplay,
                petContext: allPetsContextString,
                history: history
            )

            let doctorMsg = DoctorMessage(kind: .doctor(DoctorResponse(from: response)))

            if case .doctor(let dr) = doctorMsg.kind {
                let urgencyRaw: String? = dr.urgency.map { u in
                    switch u {
                    case .watchAtHome:  return "watchAtHome"
                    case .vetWithin24h: return "vetWithin24h"
                    case .vetNow:       return "vetNow"
                    }
                }
                sessionStore.append(
                    StoredMessage(isUser: false, displayText: dr.displayText, rawText: dr.rawText, urgencyRaw: urgencyRaw),
                    to: sessionId
                )
            }

            await MainActor.run {
                withAnimation(Motion.softEaseOut) {
                    messages.append(doctorMsg)
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Chat History View

struct ChatHistoryView: View {
    @ObservedObject private var sessionStore = ChatSessionStore.shared
    @Environment(\.dismiss) private var dismiss
    let onSelectSession: (ChatSession) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if sessionStore.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 44))
                            .foregroundStyle(PawlyColors.slate.opacity(0.35))
                        Text("No saved chats yet")
                            .font(PawlyFont.bodyLarge.weight(.semibold))
                            .foregroundStyle(PawlyColors.ink)
                        Text("Your conversations with Chintu Ji will appear here.")
                            .font(PawlyFont.bodyMedium)
                            .foregroundStyle(PawlyColors.slate)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(sessionStore.sessions) { session in
                            Button {
                                onSelectSession(session)
                                dismiss()
                            } label: {
                                SessionRow(session: session)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                sessionStore.delete(sessionId: sessionStore.sessions[idx].id)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(PawlyColors.canvas.ignoresSafeArea())
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(PawlyColors.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .tint(PawlyColors.navy)
                }
            }
        }
    }
}

private struct SessionRow: View {
    let session: ChatSession

    private var preview: String {
        session.messages.last(where: { !$0.isUser })?.displayText
            ?? session.messages.last?.displayText
            ?? "Empty chat"
    }

    private var messageCount: Int { session.messages.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(session.title)
                    .font(PawlyFont.bodyMedium.weight(.semibold))
                    .foregroundStyle(PawlyColors.ink)
                    .lineLimit(1)
                Spacer()
                Text(session.updatedAt, style: .relative)
                    .font(PawlyFont.captionSmall)
                    .foregroundStyle(PawlyColors.slate.opacity(0.6))
            }
            Text(preview)
                .font(PawlyFont.caption)
                .foregroundStyle(PawlyColors.slate)
                .lineLimit(2)
            Text("\(messageCount) message\(messageCount == 1 ? "" : "s")")
                .font(PawlyFont.captionSmall)
                .foregroundStyle(PawlyColors.slate.opacity(0.5))
        }
        .padding(.vertical, 6)
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
    let displayText: String
    let urgency: DoctorUrgency?
    let rawText: String

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

    init(displayText: String, urgency: DoctorUrgency?, rawText: String) {
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
