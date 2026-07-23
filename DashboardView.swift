import SwiftUI

struct DashboardView: View {
    
    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double
    @Binding var goals: [Goal]
    
    @State private var showTutorialSheet = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Image("background3")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 40) {
                    Text("Your Financial Dashboard")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.black)
                    
                    Button {
                        showTutorialSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundColor(.black)
                            Text("Tutorial")
                                .bold()
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: 110)
                        .padding()
                        .background(Color.fromHex("#308cc9"))
                        .cornerRadius(12)
                    }
                    .sheet(isPresented: $showTutorialSheet) {
                        TutorialSheetView2()
                    }
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        DashboardIconButton(
                            title: "Banking Basics",
                            systemIcon: "banknote",
                            destination: BankingBasicsView()
                        )
                        
                        DashboardIconButton(
                            title: "View Transactions",
                            systemIcon: "list.bullet",
                            destination: BudgetView(
                                items: $items,
                                mainBalance: $mainBalance,
                                savingsBalance: $savingsBalance
                            )
                        )
                        
                        DashboardIconButton(
                            title: "Spendings",
                            systemIcon: "cart.fill",
                            destination: TransactionsView(
                                items: $items,
                                mainBalance: $mainBalance,
                                savingsBalance: $savingsBalance
                            )
                        )
                        
                        DashboardIconButton(
                            title: "Income",
                            systemIcon: "dollarsign.circle",
                            destination: IncomeView(
                                items: $items,
                                mainBalance: $mainBalance,
                                savingsBalance: $savingsBalance
                            )
                        )
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        DashboardIconButton(
                            title: "Saving Goals",
                            systemIcon: "target",
                            destination: GoalsView(
                                items: $items,
                                mainBalance: $mainBalance,
                                goals: $goals
                            )
                        )
                        .frame(width: 200) // fixed width for centering
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    
                }
                .padding()
            }
        }
        .navigationTitle("Dashboard")
    }
}

struct DashboardIconButton<Destination: View>: View {
    let title: String
    let systemIcon: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: systemIcon)
                    .font(.system(size: 30))
                    .foregroundColor(.black)
                
                Text(title)
                    .bold()
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 76)
            .padding()
            .background(Color.fromHex("#308cc9"))
            .foregroundColor(.black)
            .cornerRadius(12)
        }
    }
}
