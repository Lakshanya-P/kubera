import SwiftUI

struct IncomeView: View {

    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double

    @State private var incomeTitle = ""
    @State private var incomeAmountText = ""

    private var canAdd: Bool {
        !incomeTitle.isEmpty && (Double(incomeAmountText) ?? 0) > 0
    }

    var body: some View {
        ZStack {
            AppBackground(image: "background2")

            CenteredScrollView(maxWidth: 640) {
                VStack(spacing: Theme.Space.l) {

                    VStack(spacing: Theme.Space.xs) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.secondary)
                        Text("Add Income")
                            .font(.largeTitle.weight(.heavy))
                            .foregroundStyle(Theme.ink)
                        Text("Balance: \(mainBalance, format: .currency(code: "USD"))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                    }
                    .padding(.top, Theme.Space.m)

                    VStack(spacing: Theme.Space.s) {
                        KidTextField(placeholder: "Income source (e.g. Allowance)", text: $incomeTitle)
                        KidTextField(placeholder: "Amount", text: $incomeAmountText, keyboard: .decimal)

                        Button("Add Income") { addIncome() }
                            .buttonStyle(PrimaryButtonStyle(fill: Theme.secondary, icon: "plus"))
                            .disabled(!canAdd)
                            .opacity(canAdd ? 1 : 0.5)
                            .tutorialAnchor("in.add")
                    }
                    .card()
                    .tutorialAnchor("in.card")
                }
            }
        }
        .navigationTitle("Income")
        .coachMarks(.income)
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
