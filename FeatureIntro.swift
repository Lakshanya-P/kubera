import SwiftUI

// MARK: - Per-feature coach-mark tour
//
// A spotlight walkthrough (like the main tutorial) that highlights the key
// controls inside each dashboard feature. It appears once the first time a
// feature is opened, has a "?" replay button, and is fully skippable.

struct CoachStep: Identifiable {
    let id = UUID()
    let anchor: String?      // element to spotlight (reuses `.tutorialAnchor`)
    let title: String
    let text: String
}

struct CoachTour {
    let id: String           // used for the "seen once" flag
    let color: Color
    let steps: [CoachStep]
}

extension CoachTour {
    static let banking = CoachTour(id: "banking", color: Theme.primary, steps: [
        CoachStep(anchor: "banking.lessons", title: "Pick a lesson",
                  text: "Swipe left or right to see all four lessons, then tap Start. Each one has a fun mini-game!")
    ])
    static let transactions = CoachTour(id: "transactions", color: Theme.purple, steps: [
        CoachStep(anchor: "tx.balance", title: "Your balance",
                  text: "This shows how much money you have right now."),
        CoachStep(anchor: "tx.chart", title: "Where it goes",
                  text: "This chart shows what you spend your money on."),
        CoachStep(anchor: "tx.list", title: "Your history",
                  text: "Every time you earn or spend, it shows up in this list.")
    ])
    static let spending = CoachTour(id: "spending", color: Theme.coral, steps: [
        CoachStep(anchor: "sp.card", title: "Add what you bought",
                  text: "Type what you bought, the price, and pick a category like food or fun."),
        CoachStep(anchor: "sp.add", title: "Track your spending",
                  text: "Then tap here — I'll subtract it from your balance.")
    ])
    static let income = CoachTour(id: "income", color: Theme.secondary, steps: [
        CoachStep(anchor: "in.card", title: "Add your money",
                  text: "Type where the money came from and how much you got."),
        CoachStep(anchor: "in.add", title: "Grow your balance",
                  text: "Tap here to add it to your balance!")
    ])
    static let investment = CoachTour(id: "investment", color: Theme.teal, steps: [
        CoachStep(anchor: "inv.header", title: "Your net worth",
                  text: "You start with 100 stripes. This is your net worth — it grows as your stocks rise!"),
        CoachStep(anchor: "inv.market", title: "Trending stocks",
                  text: "These are the 5 most popular stocks right now. Tap any one to buy or sell shares."),
        CoachStep(anchor: "inv.seeall", title: "Find any company",
                  text: "Tap “See all” to open every stock and search — even by the real company name, like “Netflix”!"),
        CoachStep(anchor: "inv.market", title: "Trends & the 1-day rule",
                  text: "In the buy window you can view a stock's trend over a week, month, or year. Remember: you must hold a stock for 1 whole day before you can sell it — no super-fast trading!"),
        CoachStep(anchor: "inv.leaderboard", title: "Climb the leaderboard",
                  text: "Grow your net worth and race the other players to the top. Buy low, sell high!")
    ])
    static let goals = CoachTour(id: "goals", color: Theme.accent, steps: [
        CoachStep(anchor: "goal.display", title: "Track your goals",
                  text: "Your goals and their progress rings show up here as you save."),
        CoachStep(anchor: "goal.new", title: "Make a goal",
                  text: "Name something you're saving for and set how much you need.")
    ])
}

// MARK: - Spotlight overlay

private struct CoachOverlay: View {
    let tour: CoachTour
    @Binding var index: Int
    let anchors: [String: Anchor<CGRect>]
    @ObservedObject var speech: SpeechManager
    let onFinish: () -> Void

    private var step: CoachStep { tour.steps[index] }
    private var isLast: Bool { index == tour.steps.count - 1 }
    private var narration: String { "\(step.title). \(step.text)" }

    var body: some View {
        GeometryReader { proxy in
            let rect: CGRect? = step.anchor.flatMap { key in anchors[key].map { proxy[$0] } }
            // Place the callout in whichever gap — above or below the highlighted
            // area — has more room, so it never covers the spotlighted feature.
            let spaceAbove = rect?.minY ?? 0
            let spaceBelow = proxy.size.height - (rect?.maxY ?? proxy.size.height)
            let calloutAtTop = spaceAbove > spaceBelow

            ZStack {
                Color.black.opacity(0.6)
                    .reverseMask {
                        if let rect {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .frame(width: rect.width + 14, height: rect.height + 14)
                                .position(x: rect.midX, y: rect.midY)
                        }
                    }

                if let rect {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tour.color, lineWidth: 3)
                        .frame(width: rect.width + 14, height: rect.height + 14)
                        .position(x: rect.midX, y: rect.midY)
                }

                callout
                    .frame(maxWidth: 520)
                    .padding(Theme.Space.m)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: calloutAtTop ? .top : .bottom)
            }
        }
    }

    private var callout: some View {
        VStack(spacing: Theme.Space.s) {
            HStack(alignment: .top, spacing: Theme.Space.s) {
                Image("tiger")
                    .resizable().scaledToFit().frame(width: 52, height: 52)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title).font(.headline).foregroundStyle(Theme.ink)
                    Text(step.text)
                        .font(.subheadline).foregroundStyle(Theme.ink.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack {
                Button {
                    speech.toggleSpeech(for: narration)
                } label: {
                    Label(speech.isSpeaking ? "Pause" : "Read aloud",
                          systemImage: speech.isSpeaking ? "pause.fill" : "speaker.wave.2.fill")
                }
                .font(.subheadline)
                .tint(tour.color)
                Spacer()
                Button("Skip") { onFinish() }
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }

            HStack(spacing: Theme.Space.s) {
                if index > 0 {
                    Button {
                        speech.stop()
                        withAnimation { index -= 1 }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 46)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.ink.opacity(0.5))
                }
                Button {
                    speech.stop()
                    if isLast { onFinish() } else { withAnimation { index += 1 } }
                } label: {
                    Text(isLast ? "Got it! 🎉" : "Next")
                }
                .buttonStyle(PrimaryButtonStyle(fill: tour.color))
            }

            Text("Step \(index + 1) of \(tour.steps.count)")
                .font(.caption)
                .foregroundStyle(Theme.ink.opacity(0.5))
        }
        .card(padding: Theme.Space.m)
    }
}

// MARK: - Modifier

private struct CoachMarksModifier: ViewModifier {
    let tour: CoachTour
    let autoStart: Bool
    @Binding var trigger: Bool
    @AppStorage private var seen: Bool
    @State private var active = false
    @State private var index = 0
    @StateObject private var speech = SpeechManager()

    init(tour: CoachTour, autoStart: Bool, trigger: Binding<Bool>) {
        self.tour = tour
        self.autoStart = autoStart
        _trigger = trigger
        _seen = AppStorage(wrappedValue: false, "coachSeen_\(tour.id)")
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { start() } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("Show tutorial")
                }
            }
            .onAppear {
                if autoStart && !seen {
                    seen = true
                    start()
                }
            }
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    seen = true
                    start()
                    trigger = false
                }
            }
            .overlayPreferenceValue(TutorialAnchorKey.self) { anchors in
                if active {
                    CoachOverlay(tour: tour, index: $index, anchors: anchors, speech: speech) {
                        speech.stop()
                        withAnimation { active = false }
                    }
                    .transition(.opacity)
                }
            }
    }

    private func start() {
        index = 0
        withAnimation { active = true }
    }
}

extension View {
    /// Shows a first-time spotlight tour for a feature, with a replay button.
    func coachMarks(_ tour: CoachTour, autoStart: Bool = true, trigger: Binding<Bool> = .constant(false)) -> some View {
        modifier(CoachMarksModifier(tour: tour, autoStart: autoStart, trigger: trigger))
    }
}
