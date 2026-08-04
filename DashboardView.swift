import SwiftUI

struct DashboardView: View {

    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double
    @Binding var goals: [Goal]

    @State private var showTutorial = false

    var body: some View {
        ZStack {
            AppBackground(image: "background3")

            CenteredScrollView {
                VStack(spacing: Theme.Space.m) {

                    Text("Your Dashboard")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Theme.ink)

                    // MARK: - Balance chip
                    HStack(spacing: 6) {
                        Text("Balance")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                        Text(mainBalance, format: .currency(code: "USD"))
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(mainBalance >= 0 ? Theme.secondary : Theme.coral)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // MARK: - Module grid (2 columns, matching the tutorial)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Space.s),
                                        GridItem(.flexible(), spacing: Theme.Space.s)],
                              spacing: Theme.Space.s) {
                        DashboardTile(title: "Transactions", icon: "list.bullet.rectangle.fill", color: Theme.purple) {
                            BudgetView(items: $items, mainBalance: $mainBalance, savingsBalance: $savingsBalance)
                        }
                        .tutorialAnchor("dash.transactions")
                        DashboardTile(title: "Spending", icon: "cart.fill", color: Theme.coral) {
                            TransactionsView(items: $items, mainBalance: $mainBalance, savingsBalance: $savingsBalance)
                        }
                        .tutorialAnchor("dash.spending")
                        DashboardTile(title: "Income", icon: "dollarsign.circle.fill", color: Theme.secondary) {
                            IncomeView(items: $items, mainBalance: $mainBalance, savingsBalance: $savingsBalance)
                        }
                        .tutorialAnchor("dash.income")
                        DashboardTile(title: "Saving Goals", icon: "target", color: Theme.accent) {
                            GoalsView(items: $items, mainBalance: $mainBalance, goals: $goals)
                        }
                        .tutorialAnchor("dash.goals")
                        DashboardTile(title: "Banking Basics", icon: "banknote.fill", color: Theme.primary) {
                            BankingBasicsView()
                        }
                        .tutorialAnchor("dash.banking")
                        DashboardTile(title: "Investment", icon: "chart.line.uptrend.xyaxis", color: Theme.teal) {
                            InvestmentView()
                        }
                        .tutorialAnchor("dash.investment")
                    }

                    Button {
                        showTutorial = true
                    } label: {
                        Text("Replay Tutorial")
                    }
                    .buttonStyle(PrimaryButtonStyle(fill: Theme.ink.opacity(0.85), icon: "play.fill"))
                    .fullCover(isPresented: $showTutorial) {
                        TutorialFlowView(mode: .dashboard)
                    }
                }
            }
        }
        .navigationTitle("Dashboard")
        .inlineNavigationTitle()
    }
}

// MARK: - Dashboard Tile

struct DashboardTile<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(Theme.Space.m)
            .background(color, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .shadow(color: color.opacity(0.35), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
    }
}
