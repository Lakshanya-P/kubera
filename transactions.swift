import SwiftUI

struct TransactionsView: View {
    
    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double
    
    @State private var title = ""
    @State private var amountText = ""
    @State private var category: BudgetItem.Category = .food
    
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            Image("background1")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    Text("Add Expense")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.black)
                    
                    VStack(spacing: 15) {
                        
                        ZStack(alignment: .leading) {
                            if title.isEmpty {
                                Text("Title")
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.leading, 12)
                            }
                            
                            TextField("", text: $title)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.6))
                                )
                                .foregroundColor(.black)
                                .accentColor(.black)
                        }
                        
                        ZStack(alignment: .leading) {
                            if amountText.isEmpty {
                                Text("Amount")
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.leading, 12)
                            }
                            
                            TextField("", text: $amountText)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.6))
                                )
                                .foregroundColor(.black)
                                .accentColor(.black)
                        }
                        
                        Picker("Category", selection: $category) {
                            ForEach(BudgetItem.Category.allCases.filter { $0 != .deposit }, id: \.self) { cat in
                                Text(cat.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.6))
                        )
                    }
                    .padding()
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(16)
                    
                    Button("Add Expense") {
                        addTransaction()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.green.opacity(0.85))
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationTitle("Spendings")
        .alert("Insufficient Funds", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
    }
    
    func addTransaction() {
        guard let amount = Double(amountText),
              amount > 0,
              !title.isEmpty else { return }
        
        if mainBalance < amount {
            showAlert = true
            return
        }
        
        mainBalance -= amount
        
        items.append(
            BudgetItem(
                title: title,
                amount: amount,
                category: category
            )
        )
        
        title = ""
        amountText = ""
    }
}
