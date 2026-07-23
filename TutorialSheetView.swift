import SwiftUI
import AVFoundation

class SpeechManager: ObservableObject {
    let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isPaused = false
    
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


struct TutorialSheetView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var speechManager = SpeechManager()
    
    let tutorialText = "Welcome to Money Managing! My name is Kubera and I'm here to teach you about financial managment! This is your beginner's guide to everything money, from basic budgeting to new financial literacy terms! Let's become smart spenders together!"
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Close Button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 5)
            
            Spacer(minLength: 1)
            
            VStack(spacing: 5) {
                
                Button {
                    speechManager.toggleSpeech(for: tutorialText)
                } label: {
                    Image(systemName: speechManager.isSpeaking ? "pause.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                ScrollView {
                    Text(tutorialText)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            }
            .frame(maxWidth: 500)
            .padding()
            
            Spacer(minLength: 5)
        }
        .presentationDetents([.medium])
    }
}

struct TutorialSheetView1: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var speechManager = SpeechManager()
    
    let tutorialText = "There are four lessons with varying difficulty. Go through them to learn more about banking and financial literacy! Together, let's learn about being a smart spender!"
    
    var body: some View {
        VStack(spacing: 20) {
            
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 5)
            
            Spacer(minLength: 10)
            
            VStack(spacing: 16) {
                
                Button {
                    speechManager.toggleSpeech(for: tutorialText)
                } label: {
                    Image(systemName: speechManager.isSpeaking ? "pause.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                ScrollView {
                    Text(tutorialText)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            }
            .frame(maxWidth: 500)
            .padding()
            
            Spacer(minLength: 10)
        }
        .presentationDetents([.medium])
    }
}


struct TutorialSheetView2: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var speechManager = SpeechManager()
    
    let tutorialText = "This is your very own personal dashboard! Here, not only can you learn more about spending & saving, but you can also keep track of your finances! Set goals and find out what you're spending money on and learn to budget accordingly. "
    
    var body: some View {
        VStack(spacing: 20) {
            
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 5)
            
            Spacer(minLength: 10)
            
            VStack(spacing: 16) {
                
                Button {
                    speechManager.toggleSpeech(for: tutorialText)
                } label: {
                    Image(systemName: speechManager.isSpeaking ? "pause.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                ScrollView {
                    Text(tutorialText)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            }
            .frame(maxWidth: 500)
            .padding()
            
            Spacer(minLength: 10)
        }
        .presentationDetents([.medium])
    }
}



