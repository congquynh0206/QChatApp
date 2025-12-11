//
//  LoginView.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import SwiftUI

struct LoginView : View {
    @EnvironmentObject var viewModel : AuthViewModel
    @State var email: String = ""
    @State var password: String = ""
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    var body: some View {
        NavigationStack{
            VStack{
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 120)
                CustomTextField(placeholder: "Your email", text: $email , systemIcon: "envelope", secret: false)
                CustomTextField(placeholder: "Password", text: $password , systemIcon: "lock",secret: true)
                HStack {
                    Spacer()
                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text("Forgot Password?")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.blue)
                    }
                }
                .padding(.trailing, 5)
                Button{
                    Task{
                        do{
                            try await viewModel.login(email: email, password: password)
                        } catch{
                            errorMessage = error.localizedDescription
                            showError = true
                            password = ""
                        }
                    }
                }label: {
                    Text("Login")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 25)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 15)
                .disabled(email.isEmpty || password.isEmpty)
                
                NavigationLink{
                    RegisterView()
                }label: {
                    HStack{
                        Text("Don't have an account?")
                        Text("Register now").bold()
                    }.font(.footnote)
                        .padding(.top, 10)
                }
                .alert("Error", isPresented: $showError){
                    Button("OK", role: .cancel) {}
                }message: {
                    Text(errorMessage)
                }
                
            }.padding()
                .padding(.bottom,50)
        }
    }
}
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var systemIcon: String? = nil
    var secret: Bool = false
    
    var body: some View {
        HStack {
            // Nếu có icon thì hiển thị
            if let icon = systemIcon {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
            }
            if secret {
                SecureField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}


#Preview {
    LoginView()
}
