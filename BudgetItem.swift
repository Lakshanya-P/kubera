import SwiftUI

struct BudgetItem: Identifiable {
    let id = UUID()
    var title: String
    var amount: Double
    var category: Category
    let date = Date()
    
    enum Category: String, CaseIterable, Identifiable {
        case food = "Food"
        case shopping = "Shopping"
        case entertainment = "Entertainment"
        case deposit = "Income"
        
        var id: String { self.rawValue }
    }
}

extension BudgetItem.Category {
    var color: Color {
        switch self {
        case .food:
            return Color.fromHex("#3bb898")
        case .shopping:
            return Color.fromHex("#74c7e2")
        case .entertainment:
            return Color.fromHex("#68c5c0")
        case .deposit:
            return Color.fromHex("#1bb073")
        }
    }
}
