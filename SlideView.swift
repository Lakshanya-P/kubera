import SwiftUI

// MARK: - Slide Model

struct Slide {
    let title: String
    let content: String
    let imageName: String?
    let game: GameType?
}

enum GameType {
    case multipleChoice(question: String, options: [String], correctIndex: Int)
    case math(question: String, answer: Int)
    case needsVsWants
}

// MARK: - Slide View

struct SlideView: View {

    let slide: Slide

    @State private var selectedIndex: Int? = nil
    @State private var mathAnswer: String = ""
    @State private var feedback: String = ""

    // Needs vs Wants State
    @State private var needs: [String] = []
    @State private var wants: [String] = []
    @State private var items: [String] = ["Food", "Shelter", "Video Game", "Candy"]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.m) {

                // Mascot + title
                VStack(spacing: Theme.Space.s) {
                    Image("tiger")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 70)
                        .accessibilityHidden(true)

                    Text(slide.title)
                        .font(.title2.weight(.heavy))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink)
                }

                Text(slide.content)
                    .font(.body)
                    .foregroundStyle(Theme.ink.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let game = slide.game {
                    Divider()
                    gameView(game)
                }

                if !feedback.isEmpty {
                    Text(feedback)
                        .font(.headline)
                        .foregroundStyle(Theme.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .card()
            .responsiveWidth()
        }
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
                    .font(.headline)
                    .foregroundStyle(Theme.ink)

                ForEach(options.indices, id: \.self) { index in
                    Button {
                        selectedIndex = index
                        flashFeedback(index == correctIndex ? "✅ That’s correct!" : "❌ Hmm… try again!")
                    } label: {
                        Text(options[index])
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (selectedIndex == index ? Theme.primary.opacity(0.15) : Color.fromHex("#F1F5FB")),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .foregroundStyle(Theme.ink)
                    }
                    .buttonStyle(.plain)
                }
            }

        case .math(let question, let answer):

            VStack(spacing: Theme.Space.s) {
                Text(question)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)

                KidTextField(placeholder: "Enter your answer", text: $mathAnswer, keyboard: .number)

                Button("Check Answer") {
                    flashFeedback(Int(mathAnswer) == answer ? "✅ Excellent money math!" : "❌ Not quite. Try again!")
                }
                .buttonStyle(PrimaryButtonStyle(fill: Theme.secondary))
            }

        case .needsVsWants:

            VStack(spacing: Theme.Space.m) {
                Text("Sort these into Needs and Wants!")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)

                HStack(alignment: .top, spacing: Theme.Space.m) {
                    sortColumn(title: "Needs", entries: needs, tint: Theme.secondary)
                    sortColumn(title: "Wants", entries: wants, tint: Theme.accent)
                }

                if !items.isEmpty {
                    Divider()
                    VStack(spacing: Theme.Space.s) {
                        ForEach(items, id: \.self) { item in
                            HStack {
                                Text(item).fontWeight(.semibold)
                                Spacer()
                                Button("Need") { assign(item, toNeeds: true) }
                                    .buttonStyle(.bordered)
                                    .tint(Theme.secondary)
                                Button("Want") { assign(item, toNeeds: false) }
                                    .buttonStyle(.bordered)
                                    .tint(Theme.accent)
                            }
                        }
                    }
                } else {
                    Text("🐯 Great job! Needs keep you safe. Wants make life fun!")
                        .font(.headline)
                        .foregroundStyle(Theme.primary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private func sortColumn(title: String, entries: [String], tint: Color) -> some View {
        VStack(spacing: Theme.Space.xs) {
            Text(title).font(.subheadline.weight(.bold)).foregroundStyle(Theme.ink)
            ForEach(entries, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.semibold))
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
    }
}
