import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}

enum AnimalCompanion {
    case kubera
}

struct UserProfile {
    var age: Int
    var hasCheckingAccount: Bool
    var knowsBankingBasics: Bool
}

struct AppColors {
    static let background = Color(hex: "FFF6D5")
    static let accent = Color(hex: "F4C430")
    static let textPrimary = Color(hex: "3A2A14")
}

