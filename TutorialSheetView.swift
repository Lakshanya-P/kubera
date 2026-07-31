import SwiftUI
import AVFoundation

class SpeechManager: ObservableObject {
    lazy var synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isPaused = false

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
    }

    func toggleSpeech(for text: String) {

        if synthesizer.isSpeaking {

            if synthesizer.isPaused {
                synthesizer.continueSpeaking()
                isPaused = false
                isSpeaking = true
            } else {
                synthesizer.pauseSpeaking(at: .word)
                isPaused = true
                isSpeaking = false
            }

        } else {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5

            synthesizer.speak(utterance)
            isSpeaking = true
            isPaused = false
        }
    }
}

// MARK: - Reusable tutorial sheet

/// One kid-friendly tutorial card with Kubera, read-aloud, and a close button.
/// The named wrappers below feed it the right text for each screen.
struct KuberaTutorial: View {

    let text: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechManager = SpeechManager()

    var body: some View {
        ZStack {
            AppBackground(image: "background3")

            VStack(spacing: Theme.Space.m) {

                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.ink.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }

                Image("tiger")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 90)
                    .accessibilityHidden(true)

                ScrollView {
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink.opacity(0.85))
                }

                Button {
                    speechManager.toggleSpeech(for: text)
                } label: {
                    Label(speechManager.isSpeaking ? "Pause" : "Read aloud",
                          systemImage: speechManager.isSpeaking ? "pause.fill" : "speaker.wave.2.fill")
                }
                .buttonStyle(PrimaryButtonStyle(fill: Theme.primary))
            }
            .card()
            .responsiveWidth(520)
            .padding()
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Screen-specific wrappers

struct TutorialSheetView: View {
    var body: some View {
        KuberaTutorial(text: "Welcome to Money Managing! My name is Kubera and I'm here to teach you about financial management! This is your beginner's guide to everything money, from basic budgeting to new financial literacy terms. Let's become smart spenders together!")
    }
}

struct TutorialSheetView1: View {
    var body: some View {
        KuberaTutorial(text: "There are four lessons with varying difficulty. Go through them to learn more about banking and financial literacy! Together, let's learn about being a smart spender!")
    }
}

struct TutorialSheetView2: View {
    var body: some View {
        KuberaTutorial(text: "This is your very own personal dashboard! Here, not only can you learn more about spending and saving, but you can also keep track of your finances. Set goals, find out what you're spending money on, and learn to budget accordingly.")
    }
}
