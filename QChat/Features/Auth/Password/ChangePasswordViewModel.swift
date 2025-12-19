//
//  ChangePasswordViewModel.swift
//  QChat
//
//  Created by Trangptt on 15/12/25.
//
import SwiftUI

@MainActor
class ChangePasswordViewModel : ObservableObject {
    // Input
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmNewPassword = ""
    
    // State
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var showSuccess = false
    
    // Validation: Mật khẩu khớp và đủ độ dài
        var isFormValid: Bool {
            return !currentPassword.isEmpty
                && !newPassword.isEmpty
                && newPassword == confirmNewPassword
                && newPassword.count >= 6
        }
        
        // Hàm update gọi sang AuthViewModel
        func updatePassword(authViewModel: AuthViewModel) async {
            guard newPassword == confirmNewPassword else {
                errorMessage = "Confirm password doesn't match!"
                showError = true
                return
            }
            
            isLoading = true
            
            do {
                try await authViewModel.updatePassword(oldPass: currentPassword, newPass: newPassword)
                
                isLoading = false
                showSuccess = true
                // Reset field sau khi thành công
                currentPassword = ""
                newPassword = ""
                confirmNewPassword = ""
                
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
}
