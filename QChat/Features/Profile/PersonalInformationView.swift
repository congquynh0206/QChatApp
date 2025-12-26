//
//  PersonalInformationView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct PersonalInformationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    // State dữ liệu
    @State private var username: String = ""
    @State private var email: String = ""
    
    // State xác nhận an toàn
    @State private var confirmEmail: String = ""
    @State private var showConfirmationAlert = false
    
    // State UI
    @State private var isLoading = false
    @State private var showResultAlert = false
    @State private var resultMessage = ""
    @State private var isEmailChanged = false
    
    var body: some View {
        Form {
            // Sec 1: User Details
            Section(header: Text("User Details")) {
                
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    TextField("Username", text: $username)
                        .textContentType(.username)
                }
            }
            
            // Sec 2: Contact Info
            Section(header: Text("Contact Info"), footer: Text("Changing email will log you out immediately. Please ensure the email is correct.")) {
                VStack (alignment: .leading){
                    Text("Email").foregroundStyle(.gray)
                    
                    CustomTextField(placeholder: "Email", text: $email, systemIcon: "envelope", secret: false)
                }
                
                
                // Ô nhập lại Email (Chỉ hiện khi email khác email gốc)
                if email != authViewModel.currentUser?.email {
                    
                    VStack (alignment: .leading){
                        Text("Confirm Email").foregroundStyle(.gray)
                        
                        CustomTextField(placeholder: "Confirm Email", text: $confirmEmail, systemIcon: "envelope", secret: false)
                    }
                    
                    // Thông báo lỗi nếu không khớp
                    if !confirmEmail.isEmpty && email != confirmEmail {
                        Text("Email confirmation does not match.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Sec 3: Button
            Section {
                HStack {
                    Spacer()
                    
                    CustomButton(title: "Save Changes", isValid: checkFormValidity()) {
                        // Logic xử lý nút bấm
                        if email != authViewModel.currentUser?.email {
                            showConfirmationAlert = true
                        } else {
                            performUpdate()
                        }
                    }
                    Spacer()
                }
            }.listRowBackground(Color.clear)
                
        }
        .navigationTitle("Personal Infomation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = authViewModel.currentUser {
                self.username = user.username
                self.email = user.email
                // Gán confirmEmail bằng email gốc ban đầu để đỡ phải nhập nếu không đổi
                self.confirmEmail = user.email
            }
        }
        // Hỏi xác nhận lần cuối
        .alert("Confirm Email Change", isPresented: $showConfirmationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, Log me out", role: .destructive) {
                performUpdate()
            }
        } message: {
            Text("Are you sure your new email is:\n\n\(email)\n\nIf this is wrong, you will be locked out of your account.")
        }
        // Thông báo kết quả
        .alert("Update Profile", isPresented: $showResultAlert) {
            Button("OK") {
                // Nếu bị logout thì view sẽ tự đóng do userSession nil
            }
        } message: {
            Text(resultMessage)
        }
        .disabled(isLoading)
    }
    
    // Hàm kiểm tra logic button
    func checkFormValidity() -> Bool {
        if isLoading { return false }
        guard let user = authViewModel.currentUser else { return false }
        
        let isUsernameChanged = username != user.username
        let isEmailChanged = email != user.email
        
        // Nếu không có gì thay đổi -> false
        if !isUsernameChanged && !isEmailChanged { return false }
        
        // Nếu đổi email mà confirm chưa đúng -> false
        if isEmailChanged && (email != confirmEmail) { return false }
        
        return true
    }
    
    // Hàm thực hiện update
    func performUpdate() {
        isLoading = true
        Task {
            do {
                try await authViewModel.updateInformation(username: username, newEmail: email)
                
                // Nếu code chạy đến đây tức là chỉ đổi Username (không bị logout)
                resultMessage = "Username updated successfully."
                showResultAlert = true
                
            } catch let error as NSError {
                if error.code == 100 {
                    resultMessage = "Email changed successfully. Please verify the link sent to \(email) and login again."
                    showResultAlert = true
                } else {
                    resultMessage = "Error: \(error.localizedDescription)"
                    showResultAlert = true
                }
            }
            isLoading = false
        }
    }
}

//#Preview {
//    NavigationStack {
//        PersonalInformationView()
//            .environmentObject(AuthViewModel())
//    }
//}
