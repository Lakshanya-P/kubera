import SwiftUI
import Charts

struct BudgetView: View {
    
    // Shared across app
    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double
    
    var body: some View {
        ZStack{
            Image("background2")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 25) {
                    
                    // MARK: - Balance Card
                    VStack(spacing: 8) {
                        Text("Current Balance")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("$\(mainBalance, specifier: "%.2f")")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(mainBalance >= 0 ? .green : .red)
                    }
                    .frame(maxWidth: 300)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    
                    //Spending chart
                    if !expenseItems.isEmpty {
                        
                        VStack(alignment: .leading) {
                            Text("Spending Overview")
                                .font(.title2)
                                .bold()
                            
                            Chart {
                                ForEach(expenseTotals) { item in
                                    SectorMark(
                                        angle: .value("Amount", item.total),
                                        innerRadius: .ratio(0.6)
                                    )
                                    .foregroundStyle(by: .value("Category", item.category.rawValue))
                                }
                            }
                            .frame(height: 250)
                        }
                    } else {
                        Text("No expenses yet. \n Try adding some income!")
                            .foregroundColor(.black)
                            .frame(alignment:.center)
                    }
                    
                    
                    // MARK: - Transaction List
                    VStack(alignment: .leading) {
                        Text("Recent Transactions")
                            .font(.title2)
                            .bold()
                        
                        ForEach(Array(items.reversed())) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    
                                    Text(item.title)
                                        .bold()
                                    
                                    Text(item.category.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text(item.category == .deposit ?
                                     "+$\(item.amount, specifier: "%.2f")" :
                                        "-$\(item.amount, specifier: "%.2f")")
                                .foregroundColor(item.category == .deposit ? .green : .red)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Transactions")
    }
}


// MARK: - Helpers

extension BudgetView {
    
    // Only expenses (not deposits)
    var expenseItems: [BudgetItem] {
        items.filter { $0.category != .deposit }
    }
    
    // Group expenses by category
    struct CategoryTotal: Identifiable {
        let id = UUID()
        let category: BudgetItem.Category
        let total: Double
    }
    
    var expenseTotals: [CategoryTotal] {
        let grouped: [BudgetItem.Category: [BudgetItem]] =
        Dictionary(grouping: expenseItems, by: { $0.category })
        
        var totals: [CategoryTotal] = []
        
        for (category, items) in grouped {
            let sum = items.reduce(0.0) { partial, item in
                partial + item.amount
            }
            
            totals.append(
                CategoryTotal(category: category, total: sum)
            )
        }
        
        return totals
    }
}
