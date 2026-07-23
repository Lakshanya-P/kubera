import SwiftUI

struct IncomeView: View {
    
    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double
    
    @State private var incomeTitle = ""
    @State private var incomeAmountText = ""
    
    var body: some View {
        ZStack {
            Image("background2")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    Text("Add Income")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.black)
                        .padding(.top, 40)
                    
                    VStack(spacing: 15) {
                        ZStack(alignment: .leading) {
                            if incomeTitle.isEmpty {
                                Text("Income Source")
                                    .foregroundColor(Color.black.opacity(0.7))
                                    .padding(.leading, 12)
                            }
                            TextField("", text: $incomeTitle)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.6))
                                )
                                .foregroundColor(.black)
                                .accentColor(.black)
                        }
                        
                        ZStack(alignment: .leading) {
                            if incomeAmountText.isEmpty {
                                Text("Amount")
                                    .foregroundColor(Color.black.opacity(0.7))
                                    .padding(.leading, 12)
                            }
                            TextField("", text: $incomeAmountText)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.6))
                                )
                                .foregroundColor(.black)
                                .accentColor(.black)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Button(action: {
                        addIncome()
                    }) {
                        Text("Add Income")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth:350)
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .navigationTitle("Income")
    }
    
    func addIncome() {
        guard let amount = Double(incomeAmountText),
              amount > 0,
              !incomeTitle.isEmpty else { return }
        
        mainBalance += amount
        
        items.append(
            BudgetItem(
                title: incomeTitle,
                amount: amount,
                category: .deposit
            )
        )
        
        incomeTitle = ""
        incomeAmountText = ""
    }
}
