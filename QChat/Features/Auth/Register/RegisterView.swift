//
//  RegisterView.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//
import SwiftUI

struct RegisterView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var viewModel = RegisterViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                //Logo
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 100)
                
                //Form
                CustomTextField(placeholder: "Your name", text: $viewModel.name, systemIcon: "person", secret: false)
                
                CustomTextField(placeholder: "Your email", text: $viewModel.email, systemIcon: "envelope", secret: false)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: (!viewModel.email.isEmpty && !viewModel.isValidEmail) ? 1 : 0)
                    )
                
                CustomTextField(placeholder: "Password", text: $viewModel.password, systemIcon: "lock", secret: true)
                    .overlay(alignment: .trailing) {
                        if viewModel.passwordsMatch {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .padding(.trailing, 12)
                        }
                    }
                
                // Password strength
                PasswordStrengthView(password: viewModel.password)
                
                // Confirm pass
                CustomTextField(placeholder: "Confirm Password", text: $viewModel.confirmPass, systemIcon: "lock", secret: true)
                    .overlay(alignment: .trailing) {
                        if viewModel.passwordsMatch {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .padding(.trailing, 12)
                        }
                    }
                
                // Register button
                CustomButton(title: "Register", isValid: viewModel.isFormValid){
                    Task {
                        await viewModel.registerUser(authViewModel: authViewModel)
                    }
                }
                
                
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Text("Already have an account?")
                        Text("Login now").bold()
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                }
                .contentShape(Rectangle())
            }
            .padding()
            
        }
        // Alert Thành công
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Account created successfully! We have sent a verification email to \(viewModel.email). Please check your inbox and verify your email before logging in.")
        }
        
        // Alert Lỗi
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .showLoading(viewModel.isLoading, message: "Creating Account...")
    }
    
}


#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
}
