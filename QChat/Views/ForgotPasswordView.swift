//
//  ForgotPasswordView.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//
import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss 
    
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Icon ổ khoá
            Image(systemName: "lock.rotation")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            VStack(spacing: 10) {
                Text("Reset Password")
                    .font(.title2)
                    .bold()
                
                Text("Enter your email address and we will send you a link to reset your password.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Ô input
            TextField("Enter your email", text: $email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .textInputAutocapitalization(.never)
                .padding(.horizontal)
                .keyboardType(.emailAddress)
            
            // Button
            Button {
                Task {
                    await sendResetLink()
                }
            } label: {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Send Reset Link")
                        .bold()
                }
            }
            .foregroundColor(.white)
            .frame(width: 200, height: 25)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .disabled(email.isEmpty || isLoading)
            .opacity(email.isEmpty ? 0.6 : 1)
            
            Spacer()
        }
        // Alert thông báo kết quả
        .alert("Notification", isPresented: $showAlert) {
            Button("OK") {
                if !alertMessage.contains("Error") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // Logic gọi sang ViewModel
    func sendResetLink() async {
        // Ẩn bàn phím
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        isLoading = true
        do {
            try await authViewModel.sendPasswordReset(email: email)
            alertMessage = "We have sent a password reset link to \(email). Please check your inbox (and spam folder)."
            showAlert = true
        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
            showAlert = true
        }
        isLoading = false
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthViewModel())
}
