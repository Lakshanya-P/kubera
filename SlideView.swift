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
            VStack(spacing: 25) {
                
                // Title
                Text(slide.title)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                
                // Kubera Header
                HStack {
                    Image("tiger")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 60)
                    
                    
                }
                
                // Content
                Text(slide.content)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                
                Divider()
                
                // Embedded Game
                if let game = slide.game {
                    gameView(game)
                }
                
                if !feedback.isEmpty {
                    Text(feedback)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.top)
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
    }
}

// MARK: - Game Engine

extension SlideView {
    
    @ViewBuilder
    private func gameView(_ game: GameType) -> some View {
        
        switch game {
            
            // MARK: - Multiple Choice
            
        case .multipleChoice(let question, let options, let correctIndex):
            
            VStack(alignment: .leading, spacing: 15) {
                Text(question)
                    .font(.headline)
                
                ForEach(options.indices, id: \.self) { index in
                    Button {
                        selectedIndex = index
                        
                        if index == correctIndex {
                            feedback = "✅ That’s correct!"
                        } else {
                            feedback = "❌ Hmm… try again!"
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            feedback = ""
                        }
                        
                    } label: {
                        Text(options[index])
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            }
            
            // MARK: - Math Challenge
            
        case .math(let question, let answer):
            
            VStack(spacing: 15) {
                Text(question)
                    .font(.headline)
                
                TextField("Enter your answer", text: $mathAnswer)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                
                Button("Check Answer") {
                    if Int(mathAnswer) == answer {
                        feedback = "✅ Excellent money math!"
                    } else {
                        feedback = "❌ Not quite. Try again!"
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        feedback = ""
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            // MARK: - Needs vs Wants Interactive
            
        case .needsVsWants:
            
            VStack(spacing: 20) {
                Text("Sort these into Needs and Wants!")
                    .font(.headline)
                
                HStack(alignment: .top) {
                    
                    // Needs Column
                    VStack {
                        Text("Needs")
                            .bold()
                        ForEach(needs, id: \.self) { item in
                            Text(item)
                                .padding(6)
                                .background(Color.green.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Wants Column
                    VStack {
                        Text("Wants")
                            .bold()
                        ForEach(wants, id: \.self) { item in
                            Text(item)
                                .padding(6)
                                .background(Color.orange.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Divider()
                
                // Remaining Items
                VStack {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Text(item)
                            
                            Spacer()
                            
                            Button("Need") {
                                needs.append(item)
                                items.removeAll { $0 == item }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Want") {
                                wants.append(item)
                                items.removeAll { $0 == item }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(6)
                    }
                }
                
                if items.isEmpty {
                    Text("🐯 Great job! Needs keep you safe. Wants make life fun!")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.top)
                }
            }
        }
    }
}
