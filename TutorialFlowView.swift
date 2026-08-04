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
    @AppStorage("survey_birthYear") private var birthYear = Calendar.current.component(.year, from: Date()) - 13
    @AppStorage("survey_hasChecking") private var hasChecking: Bool?

    @StateObject private var speech = SpeechManager()
    @State private var index = 0

    // Tiles shown on the dashboard tour (mirrors the real dashboard).
    private let tourTiles: [(title: String, icon: String, color: Color, id: String)] = [
        ("Transactions", "list.bullet.rectangle.fill", Theme.purple, "dash.transactions"),
        ("Spending", "cart.fill", Theme.coral, "dash.spending"),
        ("Income", "dollarsign.circle.fill", Theme.secondary, "dash.income"),
        ("Saving Goals", "target", Theme.accent, "dash.goals"),
        ("Banking Basics", "banknote.fill", Theme.primary, "dash.banking"),
        ("Investment", "chart.line.uptrend.xyaxis", Theme.teal, "dash.investment")
    ]

    private var allPages: [TutorialPage] {
        [
            TutorialPage(title: "Hi, I'm Kubera! 🐯",
                         text: "I'm your money guide. First, tell me about you!",
                         icon: "hand.wave.fill", color: Theme.primary),
            TutorialPage(title: "What's your name?",
                         text: "Pick a fun name — I'll make this app yours!",
                         icon: "person.fill", color: Theme.secondary, field: .name),
            TutorialPage(title: "How old are you?",
                         text: "This helps me pick the right tips for you.",
                         icon: "calendar", color: Theme.purple, field: .age),
            TutorialPage(title: "Have a bank account?",
                         text: "No worries either way!",
                         icon: "building.columns.fill", color: Theme.primary, field: .checking),
            TutorialPage(title: "Find your Dashboard",
                         text: "Tap “Your Dashboard” to open your money hub!",
                         icon: "hand.point.up.left.fill", color: Theme.purple, scene: .home("home.dashboard")),
            TutorialPage(title: "Your Dashboard 🏠",
                         text: "Four tiles manage your REAL money. Two tiles let you practice investing with tiger stripes. You're in charge of both!",
                         icon: "square.grid.2x2.fill", color: Theme.primary, scene: .dashboard(nil)),
            TutorialPage(title: "Transactions 📊",
                         text: "Track your REAL balance, view a spending chart, and see every dollar in and out. Knowing your numbers is the first step to budgeting!",
                         icon: "list.bullet.rectangle.fill", color: Theme.purple, scene: .dashboard("dash.transactions")),
            TutorialPage(title: "Spending 🛒",
                         text: "Log every real purchase here — food, fun, clothes, anything! Honest tracking is how smart budgeters stay in control of real money.",
                         icon: "cart.fill", color: Theme.coral, scene: .dashboard("dash.spending")),
            TutorialPage(title: "Income 💵",
                         text: "Add real money you earn or receive — allowance, gifts, jobs! Every dollar logged here grows your real balance.",
                         icon: "dollarsign.circle.fill", color: Theme.secondary, scene: .dashboard("dash.income")),
            TutorialPage(title: "Saving Goals 🎯",
                         text: "Set a REAL savings goal — a phone, a bike, a trip. Watch the ring fill as you save. Visual goals get reached faster!",
                         icon: "target", color: Theme.accent, scene: .dashboard("dash.goals")),
            TutorialPage(title: "Banking Lessons 📚",
                         text: "Learn real banking skills — accounts, interest, credit, taxes, and more! Complete lessons to earn 🐯 tiger stripes. Lessons get harder as you get older!",
                         icon: "banknote.fill", color: Theme.primary, scene: .dashboard("dash.banking")),
            TutorialPage(title: "Tiger Stripes 🐯",
                         text: "Stripes are GAME POINTS — not real money! Earn them by completing banking lessons, then invest them in the Tiger Market to practice real investing skills safely.",
                         icon: "chart.line.uptrend.xyaxis", color: Theme.teal, scene: .dashboard("dash.investment")),
            TutorialPage(title: "Go back home ⬅️",
                         text: "Tap the back arrow to return home.",
                         icon: "arrow.uturn.left", color: Theme.primary, scene: .dashboard("dash.back")),
            TutorialPage(title: "Your Info 🪪",
                         text: "Tap “Personal Information” to see your details.",
                         icon: "person.text.rectangle.fill", color: Theme.secondary, scene: .home("home.personal")),
            TutorialPage(title: "You're all set! 🎉",
                         text: "Have fun becoming a Money Master!",
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
        .onAppear {
            speech.speak(narration)
            // Initialise birth year if missing (e.g. first launch after update).
            let year = Calendar.current.component(.year, from: Date())
            if UserDefaults.standard.object(forKey: "survey_birthYear") == nil {
                birthYear = year - age
            }
        }
        .onChange(of: index) { _, _ in speech.speak(narration) }
        .onChange(of: age) { _, newAge in
            let year = Calendar.current.component(.year, from: Date())
            birthYear = year - newAge
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
                Circle().fill(page.color.opacity(0.15)).frame(width: 60, height: 60)
                Image(systemName: page.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(page.color)
            }

            Text(page.title)
                .font(.title.weight(.heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)

            Text(page.text)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink.opacity(0.8))

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
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(Theme.ink)
                    Text(page.text)
                        .font(.title3)
                        .foregroundStyle(Theme.ink.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack {
                readAloudButton
                Spacer()
                Button("Skip") { finish() }
                    .font(.headline)
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
            if speech.isSpeaking { speech.pause() }
            else if speech.isPaused { speech.resume() }
            else { speech.speak(narration) }
        } label: {
            Label(speech.isSpeaking ? "Pause" : "Play",
                  systemImage: speech.isSpeaking ? "pause.fill" : "play.fill")
                .font(.headline)
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
                        .font(.title3.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)
                .tint(Theme.ink.opacity(0.5))
            }

            Button {
                speech.stop()
                if isLast { finish() } else { withAnimation { index += 1 } }
            } label: {
                Text(isLast ? "Finish 🎉" : "Next")
                    .font(.title3.weight(.bold))
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
            AgePicker(age: $age, color: page.color)
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

    @State private var showEdit = false

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

                    Button("Update my info") { showEdit = true }
                        .buttonStyle(PrimaryButtonStyle(fill: Theme.primary, icon: "pencil"))
                }
            }
        }
        .navigationTitle("Personal Information")
        .sheet(isPresented: $showEdit) {
            EditInfoView()
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

// MARK: - Age picker (big, obvious +/- control)

struct AgePicker: View {
    @Binding var age: Int
    var color: Color = Theme.purple

    var body: some View {
        HStack(spacing: Theme.Space.l) {
            Button { if age > 4 { age -= 1 } } label: {
                Image(systemName: "minus.circle.fill").font(.system(size: 46))
            }
            .buttonStyle(.plain)

            Text("\(age)")
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .frame(minWidth: 72)
                .foregroundStyle(Theme.ink)

            Button { if age < 100 { age += 1 } } label: {
                Image(systemName: "plus.circle.fill").font(.system(size: 46))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(color)
    }
}

// MARK: - Edit info (direct editing, no tutorial)

struct EditInfoView: View {

    @AppStorage("survey_name") private var name = ""
    @AppStorage("survey_age") private var age = 13
    @AppStorage("survey_birthYear") private var birthYear = Calendar.current.component(.year, from: Date()) - 13
    @AppStorage("survey_hasChecking") private var hasChecking: Bool?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(image: "background2")

                CenteredScrollView(maxWidth: 560) {
                    VStack(spacing: Theme.Space.l) {

                        VStack(alignment: .leading, spacing: Theme.Space.s) {
                            SectionTitle("Your name")
                            KidTextField(placeholder: "Enter your name", text: $name)
                        }
                        .card()

                        VStack(spacing: Theme.Space.s) {
                            SectionTitle("Your age")
                            AgePicker(age: $age, color: Theme.purple)
                        }
                        .frame(maxWidth: .infinity)
                        .card()

                        VStack(alignment: .leading, spacing: Theme.Space.s) {
                            SectionTitle("Do you have a bank account?")
                            HStack(spacing: Theme.Space.s) {
                                choice(title: "Yes", value: true)
                                choice(title: "No", value: false)
                            }
                        }
                        .card()
                    }
                }
            }
            .navigationTitle("Edit your info")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.bold)
                }
            }
            .keyboardDoneButton()
            .onChange(of: age) { _, newAge in
                let year = Calendar.current.component(.year, from: Date())
                birthYear = year - newAge
            }
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
                .background(selected ? Theme.primary : Color.fromHex("#F1F5FB"),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(selected ? .white : Theme.ink)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TutorialFlowView()
}
