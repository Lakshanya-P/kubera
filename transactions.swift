import SwiftUI

struct TransactionsView: View {

    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double

    @State private var title = ""
    @State private var amountText = ""
    @State private var category: BudgetItem.Category = .food

    @State private var showAlert = false

    private var canAdd: Bool {
        !title.isEmpty && (Double(amountText) ?? 0) > 0
    }

    private var spendingCategories: [BudgetItem.Category] {
        BudgetItem.Category.allCases.filter { $0 != .deposit }
    }

    var body: some View {
        ZStack {
            AppBackground(image: "background1")

            CenteredScrollView(maxWidth: 640) {
                VStack(spacing: Theme.Space.l) {

                    VStack(spacing: Theme.Space.xs) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.coral)
                        Text("Add Spending")
                            .font(.largeTitle.weight(.heavy))
                            .foregroundStyle(Theme.ink)
                        Text("Balance: \(mainBalance, format: .currency(code: "USD"))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                    }
                    .padding(.top, Theme.Space.m)

                    VStack(spacing: Theme.Space.s) {
                        KidTextField(placeholder: "What did you buy?", text: $title)
                        KidTextField(placeholder: "Amount", text: $amountText, keyboard: .decimal)

                        // Category chips — wrap nicely on any width
                        VStack(alignment: .leading, spacing: Theme.Space.xs) {
                            Text("Category")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink.opacity(0.6))
                            LazyVGrid(columns: Theme.adaptiveColumns(minWidth: 110, spacing: Theme.Space.xs), spacing: Theme.Space.xs) {
                                ForEach(spendingCategories) { cat in
                                    categoryChip(cat)
                                }
                            }
                        }

                        Button("Add Spending") { addTransaction() }
                            .buttonStyle(PrimaryButtonStyle(fill: Theme.coral, icon: "minus"))
                            .disabled(!canAdd)
                            .opacity(canAdd ? 1 : 0.5)
                            .tutorialAnchor("sp.add")
                    }
                    .card()
                    .tutorialAnchor("sp.card")
                }
            }
        }
        .navigationTitle("Spending")
        .alert("Insufficient Funds", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You don't have enough balance for this purchase. Try adding income first!")
        }
        .coachMarks(.spending)
    }

    private func categoryChip(_ cat: BudgetItem.Category) -> some View {
        let selected = category == cat
        return Button {
            category = cat
        } label: {
            Text(cat.rawValue)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    selected ? cat.color : Color.fromHex("#F1F5FB"),
                    in: Capsule()
                )
                .foregroundStyle(selected ? .white : Theme.ink)
        }
        .buttonStyle(.plain)
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
