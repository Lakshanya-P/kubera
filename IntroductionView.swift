import SwiftUI

struct IntroductionView: View {

    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double
    @Binding var goals: [Goal]

    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial = false
    @State private var showTutorial = false

    var body: some View {
        ZStack {
            AppBackground(image: "background3")

            CenteredScrollView(maxWidth: 620) {
                VStack(spacing: Theme.Space.xl) {

                    // MARK: - Hero
                    VStack(spacing: Theme.Space.m) {
                        Image("tiger")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 260, maxHeight: 260)
                            .shadow(color: Theme.ink.opacity(0.15), radius: 12, y: 8)
                            .accessibilityHidden(true)

                        Text("Money Masters")
                            .font(.largeTitle.weight(.heavy))
                            .foregroundStyle(Theme.ink)

                        Text("Learn to make smart money moves — from your first bank account to planning your future. Meet Kubera and start the adventure!")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.ink.opacity(0.75))
                            .accessibilityLabel("Financial literacy introduction. Learn how to manage money and plan your future.")
                    }

                    // MARK: - Actions
                    VStack(spacing: Theme.Space.s) {
                        NavigationLink {
                            ProfileView()
                        } label: {
                            Label("Personal Information", systemImage: "person.text.rectangle.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle(fill: Theme.secondary))
                        .accessibilityHint("See the personal details you shared with Kubera")

                        NavigationLink {
                            DashboardView(
                                items: $items,
                                mainBalance: $mainBalance,
                                savingsBalance: $savingsBalance,
                                goals: $goals
                            )
                        } label: {
                            Label("Your Dashboard", systemImage: "chart.bar.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle(fill: Theme.purple))
                        .accessibilityHint("View your financial overview")
                    }
                    .card()
                }
            }
        }
        .onAppear {
            if !hasCompletedTutorial { showTutorial = true }
        }
        .fullCover(isPresented: $showTutorial) {
            TutorialFlowView()
        }
    }
}
