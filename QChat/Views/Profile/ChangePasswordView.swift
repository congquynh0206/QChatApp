//
//  ChangePasswordView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct ChangePasswordView: View {
    @StateObject var viewModel = ChangePasswordViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Input mật khẩu cũ
            CustomTextField(placeholder: "Current Password", text: $viewModel.currentPassword, systemIcon: "lock.open", secret: true)
            
            Divider().padding(.vertical, 10)
            
            // Input mật khẩu mới
            CustomTextField(placeholder: "New password", text: $viewModel.newPassword, systemIcon: "lock", secret: true)
            
            // Progress view
            PasswordStrengthView(password: viewModel.newPassword)
            
            // Confirm mật khẩu mới
            CustomTextField(placeholder: "Confirm new password", text: $viewModel.confirmNewPassword, systemIcon: "lock.shield", secret: true)
                .overlay(alignment: .trailing) {
                    if !viewModel.newPassword.isEmpty && viewModel.newPassword == viewModel.confirmNewPassword {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .padding(.trailing, 12)
                    }
                }
            // Nút Lưu thay đổi
            CustomButton(title: "Save Changes", isValid: viewModel.isFormValid) {
                Task {
                    await viewModel.updatePassword(authViewModel: authViewModel)
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Successfully", isPresented: $viewModel.showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your password is updated")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .showLoading(viewModel.isLoading, message: "Updating...")
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
            .environmentObject(AuthViewModel())
    }
}
