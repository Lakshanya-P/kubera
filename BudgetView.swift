import SwiftUI
import Charts

struct BudgetView: View {

    // Shared across app
    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double

    var body: some View {
        ZStack {
            AppBackground(image: "background2")

            CenteredScrollView {
                VStack(spacing: Theme.Space.l) {

                    // MARK: - Balance Card
                    VStack(spacing: Theme.Space.xs) {
                        Text("Current Balance")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                        Text(mainBalance, format: .currency(code: "USD"))
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(mainBalance >= 0 ? Theme.secondary : Theme.coral)
                    }
                    .frame(maxWidth: .infinity)
                    .card()
                    .tutorialAnchor("tx.balance")

                    // MARK: - Spending chart
                    VStack(alignment: .leading, spacing: Theme.Space.s) {
                        SectionTitle("Spending Overview")

                        if !expenseTotals.isEmpty {
                            Chart(expenseTotals) { item in
                                SectorMark(
                                    angle: .value("Amount", item.total),
                                    innerRadius: .ratio(0.6)
                                )
                                .foregroundStyle(by: .value("Category", item.category.rawValue))
                            }
                            .frame(height: 240)
                        } else {
                            emptyState(text: "No expenses yet.\nAdd some income, then track your spending!")
                        }
                    }
                    .card()
                    .tutorialAnchor("tx.chart")

                    // MARK: - Transaction List
                    VStack(alignment: .leading, spacing: Theme.Space.s) {
                        SectionTitle("Recent Transactions")

                        if items.isEmpty {
                            emptyState(text: "Your transactions will appear here.")
                        } else {
                            ForEach(Array(items.reversed())) { item in
                                transactionRow(item)
                                if item.id != items.first?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .card()
                    .tutorialAnchor("tx.list")
                }
            }
        }
        .navigationTitle("Transactions")
        .coachMarks(.transactions)
    }

    private func transactionRow(_ item: BudgetItem) -> some View {
        HStack(spacing: Theme.Space.s) {
            Circle()
                .fill(item.category.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: item.category == .deposit ? "arrow.down" : "cart.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.ink)
                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Theme.ink.opacity(0.5))
            }

            Spacer()

            Text(signedAmount(item))
                .fontWeight(.bold)
                .foregroundStyle(item.category == .deposit ? Theme.secondary : Theme.coral)
        }
        .padding(.vertical, 6)
    }

    private func signedAmount(_ item: BudgetItem) -> String {
        let value = item.amount.formatted(.currency(code: "USD"))
        return item.category == .deposit ? "+\(value)" : "-\(value)"
    }

    private func emptyState(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(Theme.ink.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Space.m)
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
        let grouped = Dictionary(grouping: expenseItems, by: { $0.category })
        return grouped.map { category, items in
            CategoryTotal(category: category, total: items.reduce(0.0) { $0 + $1.amount })
        }
    }
}
