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
                // Logo
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 120)
                
                // Input
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
                
                //Button
                CustomButton(title: "Login", isValid: !email.isEmpty && !password.isEmpty){
                    Task{
                        do{
                            try await viewModel.login(email: email, password: password)
                        } catch{
                            errorMessage = error.localizedDescription
                            showError = true
                            password = ""
                        }
                    }
                }
                
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
        .showLoading(viewModel.isLogging, message: "Logging...")
    }
}



//#Preview {
//    LoginView().environmentObject(AuthViewModel())
//}
