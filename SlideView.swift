import SwiftUI

// MARK: - Slide Model

struct Slide {
    let title: String
    let content: String
    let imageName: String?
    let game: GameType?
    var emoji: String = "🐯"
}

enum GameType {
    case multipleChoice(question: String, options: [String], correctIndex: Int)
    case math(question: String, answer: Int)
    case needsVsWants
}

// MARK: - Slide View

struct SlideView: View {

    let slide: Slide
    /// Called once when the player answers the game on this slide correctly.
    var onGameSolved: (() -> Void)?

    @State private var selectedIndex: Int? = nil
    @State private var mathAnswer: String = ""
    @State private var feedback: String = ""

    // Needs vs Wants state
    @State private var needs: [String] = []
    @State private var wants: [String] = []
    @State private var items: [String]

    @State private var bounce = false
    @State private var showCorrectPopup = false
    @State private var popupMessage = "Correct! 🎉"
    @State private var gameSolvedCalled = false

    init(slide: Slide, onGameSolved: (() -> Void)? = nil) {
        self.slide = slide
        self.onGameSolved = onGameSolved

        // Age-appropriate items for the needs-vs-wants sorting game.
        let band = AgeBand.current
        let startItems: [String]
        switch band {
        case .young:
            startItems = ["Food", "Shelter", "Video Game", "Candy"]
        case .mid:
            startItems = ["Food", "Rent", "Gaming Console", "School Supplies", "Takeout", "Medicine"]
        case .older:
            startItems = ["Health Insurance", "Rent", "Netflix", "Groceries", "New iPhone", "Textbooks"]
        }
        _items = State(initialValue: startItems)
    }

    var body: some View {
        let band = AgeBand.current
        ScrollView {
            VStack(spacing: Theme.Space.m) {

                Text(slide.emoji)
                    .font(.system(size: band.emojiSize))
                    .scaleEffect(bounce ? 1.06 : 0.94)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: bounce)
                    .accessibilityHidden(true)

                Text(slide.title)
                    .font(band.titleFont)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.ink)

                Text(slide.content)
                    .font(band.bodyFont)
                    .multilineTextAlignment(band == .older ? .leading : .center)
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: band == .older ? .leading : .center)

                if let game = slide.game {
                    Divider()
                    gameView(game)
                }

                if !feedback.isEmpty {
                    Text(feedback)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .card()
            .responsiveWidth()
        }
        .onAppear { bounce = true }
        // "Correct!" banner overlaid at the top of the scroll region.
        .overlay(alignment: .top) {
            if showCorrectPopup {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill").font(.title2)
                    Text(popupMessage).font(.title2.weight(.heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Theme.secondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Theme.secondary.opacity(0.4), radius: 12, y: 6)
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showCorrectPopup)
    }

    // MARK: - Correct-answer handling

    private func handleGameSolved(message: String = "Correct! 🎉") {
        guard !gameSolvedCalled else { return }
        gameSolvedCalled = true
        popupMessage = message
        withAnimation { showCorrectPopup = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showCorrectPopup = false }
        }
        onGameSolved?()
    }

    private func flashFeedback(_ message: String) {
        withAnimation { feedback = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { feedback = "" }
        }
    }
}

// MARK: - Game Engine

extension SlideView {

    @ViewBuilder
    private func gameView(_ game: GameType) -> some View {

        switch game {

        case .multipleChoice(let question, let options, let correctIndex):

            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text(question)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.ink)

                ForEach(options.indices, id: \.self) { index in
                    let isCorrect = index == correctIndex
                    let isSelected = selectedIndex == index
                    Button {
                        guard !gameSolvedCalled else { return }
                        selectedIndex = index
                        if isCorrect {
                            handleGameSolved()
                        } else {
                            flashFeedback("❌ Not quite — try again!")
                        }
                    } label: {
                        HStack {
                            Text(options[index])
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            if isSelected {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(isCorrect ? Theme.secondary : Theme.coral)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isSelected
                                ? (isCorrect ? Theme.secondary.opacity(0.18) : Theme.coral.opacity(0.12))
                                : Color.fromHex("#F1F5FB"),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

        case .math(let question, let answer):

            VStack(spacing: Theme.Space.s) {
                Text(question)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                KidTextField(placeholder: "Enter your answer", text: $mathAnswer, keyboard: .number)

                Button("Check Answer") {
                    guard !gameSolvedCalled else { return }
                    if Int(mathAnswer) == answer {
                        handleGameSolved()
                    } else {
                        flashFeedback("❌ Not quite. Try again!")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(fill: Theme.secondary))
            }

        case .needsVsWants:

            VStack(spacing: Theme.Space.m) {
                Text("Sort these into Needs and Wants!")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.ink)

                HStack(alignment: .top, spacing: Theme.Space.m) {
                    sortColumn(title: "Needs 🍎", entries: needs, tint: Theme.secondary)
                    sortColumn(title: "Wants 🎮", entries: wants, tint: Theme.accent)
                }

                if !items.isEmpty {
                    Divider()
                    VStack(spacing: Theme.Space.s) {
                        ForEach(items, id: \.self) { item in
                            HStack {
                                Text(item).font(.title3.weight(.semibold))
                                Spacer()
                                Button("Need") { assign(item, toNeeds: true) }
                                    .buttonStyle(.bordered)
                                    .tint(Theme.secondary)
                                    .controlSize(.large)
                                Button("Want") { assign(item, toNeeds: false) }
                                    .buttonStyle(.bordered)
                                    .tint(Theme.accent)
                                    .controlSize(.large)
                            }
                        }
                    }
                } else {
                    Text("🐯 Great job! Needs keep you safe. Wants make life fun!")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.primary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private func sortColumn(title: String, entries: [String], tint: Color) -> some View {
        VStack(spacing: Theme.Space.xs) {
            Text(title).font(.headline).foregroundStyle(Theme.ink)
            ForEach(entries, id: \.self) { item in
                Text(item)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(tint.opacity(0.25), in: Capsule())
                    .foregroundStyle(Theme.ink)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .top)
        .padding(Theme.Space.s)
        .background(Color.fromHex("#F1F5FB"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func assign(_ item: String, toNeeds: Bool) {
        withAnimation {
            if toNeeds { needs.append(item) } else { wants.append(item) }
            items.removeAll { $0 == item }
        }
        if items.isEmpty {
            handleGameSolved(message: "All sorted! 🎉")
        }
    }
}
