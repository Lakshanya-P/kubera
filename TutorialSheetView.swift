import SwiftUI
import AVFoundation

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private lazy var synth: AVSpeechSynthesizer = {
        let s = AVSpeechSynthesizer()
        s.delegate = self
        return s
    }()
    @Published var isSpeaking = false
    @Published var isPaused = false

    /// A warmer, higher-quality voice when the device has one available.
    static let friendlyVoice: AVSpeechSynthesisVoice? = {
        let en = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        if let premium = en.first(where: { $0.quality == .premium }) { return premium }
        if let enhanced = en.first(where: { $0.quality == .enhanced }) { return enhanced }
        let friendlyNames = ["Ava", "Samantha", "Allison", "Susan", "Karen", "Moira"]
        if let named = en.first(where: { friendlyNames.contains($0.name) }) { return named }
        return AVSpeechSynthesisVoice(language: "en-US")
    }()

    /// Removes emoji and symbols so only real words are read aloud.
    static func spokenText(_ s: String) -> String {
        let allowed = Set(".,!?'’\"$%:;()/-")
        let cleaned = s.map { ch -> Character in
            (ch.isLetter || ch.isNumber || ch.isWhitespace || allowed.contains(ch)) ? ch : " "
        }
        return String(cleaned)
            .split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
            .joined(separator: " ")
    }

    /// Speak `text` from the beginning, stopping anything already playing.
    func speak(_ text: String) {
        #if os(iOS)
        // Play narration even when the ring/silent switch is on.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        synth.stopSpeaking(at: .immediate)
        let clean = Self.spokenText(text)
        guard !clean.isEmpty else { isSpeaking = false; isPaused = false; return }
        let u = AVSpeechUtterance(string: clean)
        u.voice = Self.friendlyVoice
        u.rate = 0.44
        u.pitchMultiplier = 1.12
        u.preUtteranceDelay = 0.05
        synth.speak(u)
        isSpeaking = true
        isPaused = false
    }

    func pause() {
        guard synth.isSpeaking, !synth.isPaused else { return }
        synth.pauseSpeaking(at: .word)
        isPaused = true
        isSpeaking = false
    }

    func resume() {
        guard synth.isPaused else { return }
        synth.continueSpeaking()
        isPaused = false
        isSpeaking = true
    }

    func togglePause() {
        if isPaused { resume() } else if isSpeaking { pause() }
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
    }

    /// Kept for existing call sites: toggles pause when playing, else starts.
    func toggleSpeech(for text: String) {
        if isSpeaking || isPaused { togglePause() } else { speak(text) }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false; self.isPaused = false }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false; self.isPaused = false }
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
        KuberaTutorial(text: """
Welcome to Kubera — your personal money guide! 🐯

I'm here to help you learn about REAL money management AND give you a safe place to practice investing with tiger stripes (your own special currency — not real money!).

📋 Track real spending and income on your Dashboard
🎯 Set actual savings goals and watch them grow
🏦 Learn essential banking and financial literacy skills
🐯 Earn tiger stripes by completing lessons and invest them in the Tiger Market!

Start by exploring your Dashboard. Let's become money masters together!
""")
    }
}

struct TutorialSheetView1: View {
    var body: some View {
        KuberaTutorial(text: """
Banking Lessons — four lessons that teach REAL financial skills! 🏦

💡 What you'll learn:
• How banks work, different account types, and key banking terms
• Smart saving strategies and how compound interest grows your money
• Budgeting with debit cards and avoiding costly mistakes
• Advanced topics (credit scores, taxes, and more for older learners!)

🌟 Lessons get harder as you get older — difficulty updates automatically each year.

🐯 Tiger Stripes: Finish a lesson at a new difficulty level and earn 1 stripe to invest in the Tiger Market. You can only earn stripes once per difficulty — so as you grow, new challenges unlock!

Answer every question correctly to move forward. You've got this!
""")
    }
}

struct TutorialSheetView2: View {
    var body: some View {
        KuberaTutorial(text: """
Your Dashboard — command center for your REAL money! 💵

Here you can manage actual finances, not just tiger stripes:

📊 Transactions — See your full balance, spending chart, and history. Every real dollar tracked.
🛒 Spending — Log real purchases by category. Know exactly where your money goes.
💵 Income — Add allowance, gifts, or job earnings. Watch your real balance grow.
🎯 Saving Goals — Set a target for something you want to save up for. Track progress visually.
🏦 Banking Lessons — Learn real skills AND earn tiger stripes as you complete lessons.
📈 Tiger Market — Practice investing with tiger stripes (game points, not real money!). Learn to buy low, sell high, and compete on the leaderboard.

The first four tiles help you manage REAL money. The Tiger Market is a safe simulation where you practice with stripes before ever touching real investments!
""")
    }
}
