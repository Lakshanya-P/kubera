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
        CoachStep(anchor: "banking.lessons", title: "Learn & earn! 📚",
                  text: "Four lessons that teach REAL banking skills — terms, accounts, budgeting, credit, and more."),
        CoachStep(anchor: "banking.lessons", title: "🐯 Earn Tiger Stripes!",
                  text: "Complete a lesson at a new difficulty level to earn 1 stripe. Stripes are awarded only once per difficulty — harder difficulty = new stripe! Invest them in the Tiger Market."),
        CoachStep(anchor: "banking.lessons", title: "Age-based difficulty 🎓",
                  text: "Lessons automatically get harder as you get older! Answer every question correctly to advance — no skipping!")
    ])
    static let transactions = CoachTour(id: "transactions", color: Theme.purple, steps: [
        CoachStep(anchor: "tx.balance", title: "Your REAL balance 💵",
                  text: "This shows your actual money — not tiger stripes. Log every deposit and purchase here to stay on top of your real finances."),
        CoachStep(anchor: "tx.chart", title: "Spending chart 📊",
                  text: "See your spending broken down by category. Patterns appear fast — knowing WHERE money goes is the first step to budgeting well!"),
        CoachStep(anchor: "tx.list", title: "Full history 📜",
                  text: "Every dollar in and every dollar out, recorded here. Review it regularly to catch mistakes and stay on budget.")
    ])
    static let spending = CoachTour(id: "spending", color: Theme.coral, steps: [
        CoachStep(anchor: "sp.card", title: "Log real spending 🛒",
                  text: "Every time you spend REAL money — on food, fun, clothes, anything — log it here. This is how budgeters stay in control!"),
        CoachStep(anchor: "sp.add", title: "Tap to deduct ➖",
                  text: "Enter the amount and category, then tap to subtract from your real balance. Honest tracking = smarter spending decisions.")
    ])
    static let income = CoachTour(id: "income", color: Theme.secondary, steps: [
        CoachStep(anchor: "in.card", title: "Add real income 💵",
                  text: "Got allowance, a gift, or earned money from a job or chore? Add it here! This is your REAL money, not tiger stripes."),
        CoachStep(anchor: "in.add", title: "Grow your balance ➕",
                  text: "Tap to add it and watch your real balance grow. Every dollar tracked here helps you budget smarter and save more!")
    ])
    static let investment = CoachTour(id: "investment", color: Theme.teal, steps: [
        CoachStep(anchor: "inv.header", title: "🐯 Stripes = game points!",
                  text: "Tiger stripes are NOT real money — they're your game currency, earned from completing banking lessons. Invest them here to practice real investing skills risk-free!"),
        CoachStep(anchor: "inv.market", title: "Trending stocks 🔥",
                  text: "The 5 hottest stocks right now. Prices rise and fall like real markets! Tap any stock to buy or sell with your stripes."),
        CoachStep(anchor: "inv.seeall", title: "Browse all companies 🔎",
                  text: "Tap 'See all' to search 30+ tiger-themed companies based on real ones. Search by real name — try 'Apple' or 'Netflix'!"),
        CoachStep(anchor: "inv.market", title: "Read trends + 1-day rule ⏳",
                  text: "Tap any stock to view week, month, or year price charts. After buying, you must hold for 1 day before selling — just like real investing!"),
        CoachStep(anchor: "inv.leaderboard", title: "Race to #1! 🏆",
                  text: "Your net worth = stripes + value of your stocks. Buy low, sell high, and climb the leaderboard. Every decision teaches you real investing strategy!")
    ])
    static let goals = CoachTour(id: "goals", color: Theme.accent, steps: [
        CoachStep(anchor: "goal.display", title: "Real saving goals 🎯",
                  text: "Set a REAL money goal — a new phone, a trip, a gift. Watch the progress ring fill as you save toward it. Visual goals get reached faster!"),
        CoachStep(anchor: "goal.new", title: "Create a goal ✨",
                  text: "Name it and set a dollar target. Every time you add income, you can allocate some toward this goal. Small consistent amounts add up to big results!")
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
                    .frame(maxWidth: 560)
                    .padding(Theme.Space.m)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: calloutAtTop ? .top : .bottom)
            }
        }
        .onAppear { speech.speak(narration) }
        .onChange(of: index) { _, _ in speech.speak(narration) }
    }

    private var callout: some View {
        VStack(spacing: Theme.Space.s) {
            HStack(alignment: .top, spacing: Theme.Space.s) {
                Image("tiger")
                    .resizable().scaledToFit().frame(width: 60, height: 60)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title).font(.title3.weight(.heavy)).foregroundStyle(Theme.ink)
                    Text(step.text)
                        .font(.title3)
                        .foregroundStyle(Theme.ink.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack {
                Button { toggleAudio() } label: {
                    Label(speech.isSpeaking ? "Pause" : "Play",
                          systemImage: speech.isSpeaking ? "pause.fill" : "play.fill")
                }
                .font(.headline)
                .tint(tour.color)
                Spacer()
                Button("Skip") { onFinish() }
                    .font(.headline)
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }

            HStack(spacing: Theme.Space.s) {
                if index > 0 {
                    Button {
                        speech.stop()
                        withAnimation { index -= 1 }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.title3.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.ink.opacity(0.5))
                }
                Button {
                    speech.stop()
                    if isLast { onFinish() } else { withAnimation { index += 1 } }
                } label: {
                    Text(isLast ? "Got it! 🎉" : "Next")
                        .font(.title3.weight(.bold))
                }
                .buttonStyle(PrimaryButtonStyle(fill: tour.color))
            }

            Text("Step \(index + 1) of \(tour.steps.count)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.ink.opacity(0.5))
        }
        .card(padding: Theme.Space.m)
    }

    private func toggleAudio() {
        if speech.isSpeaking { speech.pause() }
        else if speech.isPaused { speech.resume() }
        else { speech.speak(narration) }
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
