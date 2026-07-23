import SwiftUI
import AVFoundation

struct IntroductionView: View {
    
    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double
    @Binding var goals: [Goal]
    
    @State private var showTutorialSheet = false
    private let speechSynth = AVSpeechSynthesizer()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                
                Image("background3")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        Spacer(minLength: 20)
                        
                        Image("tiger")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                maxWidth: geo.size.width * 0.7,
                                maxHeight: geo.size.height * 0.3
                            )
                            .accessibilityHidden(true)
                        
                        Text("""
Financial literacy helps you make smart money decisions — from managing your first bank account to planning for your future. Start the tutorial to learn more!
""")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                        .minimumScaleFactor(0.8)
                        .accessibilityLabel("Financial literacy introduction. Learn how to manage money and plan your future.")
                        
                        // MARK: - Start Tutorial Button
                        Button {
                            showTutorialSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Tutorial")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.fromHex("#308cc9"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Start tutorial")
                        .accessibilityHint("Opens a guided tutorial to help you learn the app")
                        .sheet(isPresented: $showTutorialSheet) {
                            TutorialSheetView()
                        }
                        
                        // MARK: - Quiz Navigation
                        NavigationLink(destination: SurveyView(
                            items: $items,
                            mainBalance: $mainBalance,
                            savingsBalance: $savingsBalance,
                            goals: $goals
                        )) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("Personal Information")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.fromHex("#308cc9"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Take initial quiz")
                        .accessibilityHint("Test your financial knowledge")
                        
                        // MARK: - Dashboard Navigation
                        NavigationLink(destination: DashboardView(
                            items: $items,
                            mainBalance: $mainBalance,
                            savingsBalance: $savingsBalance,
                            goals: $goals
                        )) {
                            HStack {
                                Image(systemName: "chart.bar")
                                Text("Your Dashboard")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.fromHex("#308cc9"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Open dashboard")
                        .accessibilityHint("View your financial overview")
                        
                        Spacer(minLength: 30)
                    }
                    .frame(maxWidth: 600) // prevents stretching on iPad
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
    }
}
