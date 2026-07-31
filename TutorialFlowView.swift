import SwiftUI

// MARK: - Spotlight anchor plumbing

/// Collects the on-screen frame of any view tagged with `.tutorialAnchor(id)`,
/// so the coach-mark overlay can spotlight it.
struct TutorialAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Tags a view so the tutorial can spotlight it by `id`.
    func tutorialAnchor(_ id: String) -> some View {
        anchorPreference(key: TutorialAnchorKey.self, value: .bounds) { [id: $0] }
    }

    /// Punches a hole in `self` in the shape of `mask` (used for the spotlight).
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask().blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}

// MARK: - Tutorial data

private enum TutorialField { case none, name, age, checking }

private enum TutorialScene {
    case card                 // full-screen Kubera card
    case home(String?)        // home-screen replica, spotlighting an anchor id
    case dashboard(String?)   // dashboard replica, spotlighting an anchor id
}

private struct TutorialPage: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let icon: String
    let color: Color
    var field: TutorialField = .none
    var scene: TutorialScene = .card
}

enum TutorialMode { case full, dashboard }

// MARK: - First-run guided tutorial

struct TutorialFlowView: View {

    var mode: TutorialMode = .full

    @Environment(\.dismiss) private var dismiss

    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial = false
    @AppStorage("survey_name") private var name = ""
    @AppStorage("survey_age") private var age = 13
    @AppStorage("survey_hasChecking") private var hasChecking: Bool?

    @StateObject private var speech = SpeechManager()
    @State private var index = 0

    // Tiles shown on the dashboard tour (mirrors the real dashboard).
    private let tourTiles: [(title: String, icon: String, color: Color, id: String)] = [
        ("Banking Basics", "banknote.fill", Theme.primary, "dash.banking"),
        ("Transactions", "list.bullet.rectangle.fill", Theme.purple, "dash.transactions"),
        ("Spending", "cart.fill", Theme.coral, "dash.spending"),
        ("Income", "dollarsign.circle.fill", Theme.secondary, "dash.income"),
        ("Investment", "chart.line.uptrend.xyaxis", Theme.teal, "dash.investment"),
        ("Saving Goals", "target", Theme.accent, "dash.goals")
    ]

    private var allPages: [TutorialPage] {
        [
            TutorialPage(title: "Hi, I'm Kubera!",
                         text: "I'll be your money guide. Let me get to know you, then show you around the app. You can skip anytime.",
                         icon: "hand.wave.fill", color: Theme.primary),
            TutorialPage(title: "What's your name?",
                         text: "Tell me your name so I can make this app feel like yours.",
                         icon: "person.fill", color: Theme.secondary, field: .name),
            TutorialPage(title: "How old are you?",
                         text: "This helps me share tips that fit you best.",
                         icon: "calendar", color: Theme.purple, field: .age),
            TutorialPage(title: "Do you have a checking account?",
                         text: "No worries either way — it just helps me know where to start.",
                         icon: "building.columns.fill", color: Theme.primary, field: .checking),
            TutorialPage(title: "Finding your Dashboard",
                         text: "This is your home screen. Tap “Your Dashboard” to open your money hub — that's where we're headed next!",
                         icon: "hand.point.up.left.fill", color: Theme.purple, scene: .home("home.dashboard")),
            TutorialPage(title: "This is your Dashboard",
                         text: "Your home base! Every feature lives here as a colorful tile. Let me show you each one.",
                         icon: "square.grid.2x2.fill", color: Theme.primary, scene: .dashboard(nil)),
            TutorialPage(title: "Banking Basics",
                         text: "Four fun lessons teach you how banking, saving, budgeting, and credit work — with mini-games.",
                         icon: "banknote.fill", color: Theme.primary, scene: .dashboard("dash.banking")),
            TutorialPage(title: "Transactions",
                         text: "See your balance and a chart of where your money goes, plus every deposit and purchase.",
                         icon: "list.bullet.rectangle.fill", color: Theme.purple, scene: .dashboard("dash.transactions")),
            TutorialPage(title: "Spending",
                         text: "Bought something? Add it here and pick a category. I'll subtract it from your balance.",
                         icon: "cart.fill", color: Theme.coral, scene: .dashboard("dash.spending")),
            TutorialPage(title: "Income",
                         text: "Earned money, like allowance? Add it here to grow your balance.",
                         icon: "dollarsign.circle.fill", color: Theme.secondary, scene: .dashboard("dash.income")),
            TutorialPage(title: "Investment",
                         text: "Investing puts your money to work so it can grow over time. Tap here to learn how!",
                         icon: "chart.line.uptrend.xyaxis", color: Theme.teal, scene: .dashboard("dash.investment")),
            TutorialPage(title: "Saving Goals",
                         text: "Set a goal like a new bike, then watch your progress ring fill as you save.",
                         icon: "target", color: Theme.accent, scene: .dashboard("dash.goals")),
            TutorialPage(title: "Heading back home",
                         text: "Done exploring? Tap the back arrow at the top-left to return to the home screen.",
                         icon: "arrow.uturn.left", color: Theme.primary, scene: .dashboard("dash.back")),
            TutorialPage(title: "Your Personal Info",
                         text: "Back on the home screen, tap “Personal Information” anytime to see the details you shared with me.",
                         icon: "person.text.rectangle.fill", color: Theme.secondary, scene: .home("home.personal")),
            TutorialPage(title: "You're all set!",
                         text: "That's the tour. Have fun becoming a Money Master!",
                         icon: "checkmark.seal.fill", color: Theme.secondary)
        ]
    }

    /// In `.dashboard` mode, only the dashboard walkthrough steps are shown.
    private var pages: [TutorialPage] {
        switch mode {
        case .full:
            return allPages
        case .dashboard:
            return allPages.filter {
                if case .dashboard = $0.scene { return true } else { return false }
            }
        }
    }

    private var page: TutorialPage { pages[index] }
    private var isLast: Bool { index == pages.count - 1 }

    private var narration: String {
        var line = "\(page.title). \(page.text)"
        if page.field == .name, !name.isEmpty { line += " Nice to meet you, \(name)." }
        return line
    }

    var body: some View {
        Group {
            switch page.scene {
            case .dashboard(let target):
                spotlightScene(target: target) { dashboardReplica }
            case .home(let target):
                spotlightScene(target: target) { homeReplica }
            default:
                cardScene
            }
        }
    }

    // MARK: - Card scene

    private var cardScene: some View {
        ZStack {
            AppBackground(image: "background3")

            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: Theme.Space.m) {
                        topBar
                        kuberaCard
                        navigationButtons
                    }
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Space.l)
                    .frame(minHeight: geo.size.height)
                }
            }
        }
    }

    private var topBar: some View {
        VStack(spacing: Theme.Space.s) {
            HStack {
                Spacer()
                Button("Skip") { finish() }
                    .font(.headline)
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }
            ProgressView(value: Double(index + 1), total: Double(pages.count))
                .tint(page.color)
            Text("Step \(index + 1) of \(pages.count)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.ink.opacity(0.5))
        }
    }

    private var kuberaCard: some View {
        VStack(spacing: Theme.Space.s) {
            Image("tiger")
                .resizable().scaledToFit().frame(height: 76)
                .accessibilityHidden(true)

            ZStack {
                Circle().fill(page.color.opacity(0.15)).frame(width: 48, height: 48)
                Image(systemName: page.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(page.color)
            }

            Text(page.title)
                .font(.title3.weight(.heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)

            Text(page.text)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink.opacity(0.75))

            readAloudButton

            inputControl
        }
        .card(padding: Theme.Space.m)
    }

    // MARK: - Spotlight scene (shared by the home & dashboard replicas)

    private func spotlightScene<Content: View>(target: String?, @ViewBuilder content: @escaping () -> Content) -> some View {
        GeometryReader { geo in
            let calloutH = min(geo.size.height * 0.36, 280)
            ZStack(alignment: .bottom) {
                AppBackground(image: "background3")

                content()
                    .padding(Theme.Space.m)
                    .padding(.bottom, calloutH)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    .overlayPreferenceValue(TutorialAnchorKey.self) { anchors in
                        GeometryReader { proxy in
                            let rect: CGRect? = target.flatMap { key in anchors[key].map { proxy[$0] } }
                            ZStack {
                                Color.black.opacity(rect == nil ? 0 : 0.55)
                                    .reverseMask {
                                        if let rect {
                                            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                                                .frame(width: rect.width + 10, height: rect.height + 10)
                                                .position(x: rect.midX, y: rect.midY)
                                        }
                                    }
                                if let rect {
                                    RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                                        .stroke(page.color, lineWidth: 3)
                                        .frame(width: rect.width + 10, height: rect.height + 10)
                                        .position(x: rect.midX, y: rect.midY)
                                }
                            }
                        }
                    }

                dashboardCallout
            }
            .overlay(alignment: .top) {
                ProgressView(value: Double(index + 1), total: Double(pages.count))
                    .tint(page.color)
                    .padding(.horizontal, Theme.Space.l)
                    .padding(.top, Theme.Space.s)
            }
        }
    }

    // MARK: - Home replica (for the "find your dashboard" step)

    private var homeReplica: some View {
        VStack(spacing: Theme.Space.l) {
            Spacer(minLength: 0)

            VStack(spacing: Theme.Space.s) {
                Image("tiger")
                    .resizable().scaledToFit().frame(maxHeight: 150)
                    .accessibilityHidden(true)
                Text("Money Masters")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(Theme.ink)
                Text("Your money hub is just one tap away.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.ink.opacity(0.7))
            }

            Spacer(minLength: 0)

            VStack(spacing: Theme.Space.s) {
                homeButton("Personal Information", "person.text.rectangle.fill", Theme.secondary)
                    .tutorialAnchor("home.personal")
                homeButton("Your Dashboard", "chart.bar.fill", Theme.purple)
                    .tutorialAnchor("home.dashboard")
            }
            .card()

            Spacer(minLength: 0)
        }
    }

    private func homeButton(_ title: String, _ icon: String, _ color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: color.opacity(0.35), radius: 10, y: 6)
    }

    // MARK: - Dashboard replica

    private var dashboardReplica: some View {
        VStack(spacing: Theme.Space.s) {
            // Mock navigation bar with a back button (the "exit" step spotlights it).
            HStack {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.9), in: Circle())
                    .tutorialAnchor("dash.back")
                Spacer()
                Text("Your Dashboard")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }

            HStack(spacing: 6) {
                Text("Balance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                Text("$120.00")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(spacing: Theme.Space.s) {
                HStack(spacing: Theme.Space.s) { tourTile(0); tourTile(1) }
                HStack(spacing: Theme.Space.s) { tourTile(2); tourTile(3) }
                HStack(spacing: Theme.Space.s) { tourTile(4); tourTile(5) }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func tourTile(_ i: Int) -> some View {
        let t = tourTiles[i]
        return VStack(spacing: 8) {
            Image(systemName: t.icon)
                .font(.system(size: 32, weight: .semibold))
            Text(t.title)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Space.s)
        .background(t.color, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .shadow(color: t.color.opacity(0.35), radius: 8, y: 4)
        .tutorialAnchor(t.id)
    }

    private var dashboardCallout: some View {
        VStack(spacing: Theme.Space.s) {
            HStack(alignment: .top, spacing: Theme.Space.s) {
                Image("tiger")
                    .resizable().scaledToFit().frame(width: 56, height: 56)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(page.title)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(page.text)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack {
                readAloudButton
                Spacer()
                Button("Skip") { finish() }
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }

            navigationButtons
        }
        .card(padding: Theme.Space.m)
        .padding(Theme.Space.m)
        .frame(maxWidth: 560)
    }

    // MARK: - Shared controls

    private var readAloudButton: some View {
        Button {
            speech.toggleSpeech(for: narration)
        } label: {
            Label(speech.isSpeaking ? "Pause" : "Read aloud",
                  systemImage: speech.isSpeaking ? "pause.fill" : "speaker.wave.2.fill")
        }
        .buttonStyle(.bordered)
        .tint(page.color)
    }

    private var navigationButtons: some View {
        HStack(spacing: Theme.Space.s) {
            if index > 0 {
                Button {
                    speech.stop()
                    withAnimation { index -= 1 }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
                .tint(Theme.ink.opacity(0.5))
            }

            Button {
                speech.stop()
                if isLast { finish() } else { withAnimation { index += 1 } }
            } label: {
                Text(isLast ? "Finish 🎉" : "Next")
            }
            .buttonStyle(PrimaryButtonStyle(fill: page.color))
        }
    }

    // MARK: - Per-step input

    @ViewBuilder
    private var inputControl: some View {
        switch page.field {
        case .name:
            KidTextField(placeholder: "Your name", text: $name)
        case .age:
            VStack(spacing: Theme.Space.xs) {
                Text("\(age)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(page.color)
                Stepper("Age", value: $age, in: 4...100)
                    .labelsHidden()
            }
        case .checking:
            HStack(spacing: Theme.Space.s) {
                choice(title: "Yes", value: true)
                choice(title: "No", value: false)
            }
        case .none:
            EmptyView()
        }
    }

    private func choice(title: String, value: Bool) -> some View {
        let selected = hasChecking == value
        return Button {
            hasChecking = value
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    selected ? page.color : Color.fromHex("#F1F5FB"),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .foregroundStyle(selected ? .white : Theme.ink)
        }
        .buttonStyle(.plain)
    }

    private func finish() {
        speech.stop()
        if mode == .full { hasCompletedTutorial = true }
        dismiss()
    }
}

// MARK: - Profile display

/// Shows the personal information collected during the tutorial. Opened from
/// the "Personal Information" button on the home screen.
struct ProfileView: View {

    @AppStorage("survey_name") private var name = ""
    @AppStorage("survey_age") private var age = 13
    @AppStorage("survey_hasChecking") private var hasChecking: Bool?

    @State private var showTutorial = false

    private var checkingText: String {
        guard let hasChecking else { return "Not set yet" }
        return hasChecking ? "Yes" : "No"
    }

    var body: some View {
        ZStack {
            AppBackground(image: "background2")

            CenteredScrollView(maxWidth: 640) {
                VStack(spacing: Theme.Space.l) {

                    VStack(spacing: Theme.Space.s) {
                        Image("tiger")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .accessibilityHidden(true)
                        Text(name.isEmpty ? "Your Profile" : "\(name)'s Profile")
                            .font(.largeTitle.weight(.heavy))
                            .foregroundStyle(Theme.ink)
                    }

                    VStack(spacing: 0) {
                        row(icon: "person.fill", label: "Name",
                            value: name.isEmpty ? "Not set yet" : name, color: Theme.secondary)
                        Divider()
                        row(icon: "calendar", label: "Age",
                            value: "\(age)", color: Theme.purple)
                        Divider()
                        row(icon: "building.columns.fill", label: "Checking account",
                            value: checkingText, color: Theme.primary)
                    }
                    .card()

                    Button("Update my info") { showTutorial = true }
                        .buttonStyle(PrimaryButtonStyle(fill: Theme.primary, icon: "pencil"))
                }
            }
        }
        .navigationTitle("Personal Information")
        .fullCover(isPresented: $showTutorial) {
            TutorialFlowView()
        }
    }

    private func row(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: Theme.Space.m) {
            ZStack {
                Circle().fill(color).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundStyle(.white)
            }
            Text(label)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(Theme.ink.opacity(0.7))
        }
        .padding(.vertical, Theme.Space.s)
    }
}

#Preview {
    TutorialFlowView()
}
