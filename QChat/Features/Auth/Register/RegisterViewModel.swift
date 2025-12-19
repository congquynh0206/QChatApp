//
//  RegisterViewModel.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import Foundation
import SwiftUI

@MainActor
class RegisterViewModel: ObservableObject {
    // 1. Dữ liệu nhập từ màn hình (Input)
    @Published var email = ""
    @Published var name = ""
    @Published var password = ""
    @Published var confirmPass = ""
    
    // 2. Trạng thái UI (State)
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var isLoading = false
    
    @Published var showSuccessAlert = false
    
    
    // Kiểm tra Email hợp lệ
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // Tính điểm độ mạnh mật khẩu (0 -> 4)
    var passwordStrengthScore: Double {
        var score: Double = 0
        if password.isEmpty { return 0 }
        
        if password.count >= 6 { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()-_=+")) != nil { score += 1 }
        
        return score
    }
    
    // Màu sắc thanh Progress
    var strengthColor: Color {
        switch passwordStrengthScore {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .gray
        }
    }
    
    // Label hiển thị chữ (Weak/Strong)
    var strengthLabel: String {
        if password.isEmpty { return "" }
        switch passwordStrengthScore {
        case 0...1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Strong"
        default: return ""
        }
    }
    
    // Kiểm tra tổng thể xem có cho bấm nút Register không
    var isFormValid: Bool {
        return !email.isEmpty
        && isValidEmail
        && !password.isEmpty
        && !name.isEmpty
        && passwordsMatch
        && password.count >= 6
    }
    
    // Check match password
    var passwordsMatch: Bool {
        return !password.isEmpty && !confirmPass.isEmpty && password == confirmPass
    }
    
    // Hàm này nhận AuthViewModel từ View truyền vào để gọi hàm đăng ký gốc
    func registerUser(authViewModel: AuthViewModel) async {
        // Double check
        guard password == confirmPass else {
            errorMessage = "Passwords do not match!"
            showError = true
            return
        }
        
        isLoading = true
        
        do {
            // Gọi hàm register gốc bên AuthViewModel
            try await authViewModel.register(email: email, password: password, userName: name)
            // Send email to verify
            try await authViewModel.sendVerificationEmail()
            // Navigate to login screen
            try authViewModel.logOut()
            isLoading = false
            showSuccessAlert = true
            // Thành công thì không cần làm gì, App tự chuyển view
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
