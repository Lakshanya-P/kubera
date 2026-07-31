import SwiftUI

import SwiftUI

extension Color {
    static func fromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r, g, b: Double
        if hex.count == 7 || hex.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
        } else {
            r = 0; g = 0; b = 0
        }
        
        return Color(red: r, green: g, blue: b)
    }
}

@main

struct FinancialLiteracyGameApp: App {
    
    // MARK: - Shared app state
    @State private var items: [BudgetItem] = []
    @State private var mainBalance: Double = 0
    @State private var savingsBalance: Double = 0
    @State private var goals: [Goal] = []
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                IntroductionView(
                    items: $items,
                    mainBalance: $mainBalance,
                    savingsBalance: $savingsBalance,
                    goals: $goals
                )
            }
            .fontDesign(.rounded)
            .tint(Theme.primary)
        }
    }
}
