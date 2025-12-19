//
//  PasswordStrengthView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct PasswordStrengthView: View {
    var password: String
    
    // Logic tính điểm
    private var passwordStrengthScore: Double {
        var score: Double = 0
        if password.isEmpty { return 0 }
        
        if password.count >= 6 { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()-_=+")) != nil { score += 1 }
        
        return score
    }
    
    // Logic màu sắc
    private var strengthColor: Color {
        switch passwordStrengthScore {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .gray
        }
    }
    
    // Logic Label
    private var strengthLabel: String {
        if password.isEmpty { return "" }
        switch passwordStrengthScore {
        case 0...1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Strong"
        default: return ""
        }
    }
    
    var body: some View {
        if !password.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                ProgressView(value: passwordStrengthScore, total: 4)
                    .accentColor(strengthColor)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                
                Text(strengthLabel)
                    .font(.caption)
                    .foregroundColor(strengthColor)
            }
            .padding(.horizontal)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.default, value: password)
        }
    }
}
