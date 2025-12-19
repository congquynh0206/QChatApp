//
//  AuthViewModel.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel : ObservableObject{
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isLogging = false
    
    init(){
        self.userSession = Auth.auth().currentUser
        Task{
            await fetchUser()
        }
    }
    func fetchUser() async {
        guard let authUser = Auth.auth().currentUser else { return }
        let userId = authUser.uid
        let authEmail = authUser.email ?? ""
        
        // 2. Lấy dữ liệu từ Firestore
        guard let snapshot = try? await Firestore.firestore().collection("users").document(userId).getDocument(),
              var data = snapshot.data() else { return }
        
        // Kiểm tra xem email trong Firestore có khớp với Auth không
        if let firestoreEmail = data["email"] as? String,
           firestoreEmail != authEmail {
            // Đồng bộ firestore theo auth
            try? await Firestore.firestore().collection("users").document(userId).updateData([
                "email": authEmail
            ])
            
            data["email"] = authEmail
        }
        
        // 4. Gán vào biến currentUser
        self.currentUser = User(dictionary: data)
    }
    
    //Login
    func login (email: String, password: String) async throws{
        isLogging = true
        do{
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            if !result.user.isEmailVerified {
                // Nếu chưa thì đăng xuất
                try logOut()
                isLogging = false
                // Ném ra lỗi để bên View hiện thông báo
                throw NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please verify your email address before logging in."])
            }
            self.userSession = result.user
            UserStatusService.shared.updateStatus(isOnline: true)
            await fetchUser()
        }catch{
            isLogging = false
            print("Lỗi: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Register
    func register (email: String, password: String, userName: String) async throws{
        do{
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let newUser = User(id: result.user.uid, email: email, username: userName, avatar: nil)
            try await Firestore.firestore().collection("users").document(result.user.uid).setData(newUser.dictionary)
            self.currentUser = newUser
        }catch{
            print(error.localizedDescription)
            throw error
        }
    }
    
    //Verify email
    func sendVerificationEmail() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification()
    }
    
    // Forgot Password
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    // Logout
    func logOut() throws{
        isLogging = false
        do{
            try  Auth.auth().signOut()
            self.currentUser = nil
            self.userSession = nil
        }catch {
            print(error.localizedDescription)
            throw error
        }
    }
    
    // Change Pass
    func updatePassword(oldPass: String, newPass: String) async throws {
        // Kiểm tra user hiện tại
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not found user."])
        }
        
        // Tạo cre từ mật khẩu cũ để kiểm tra
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPass)

        // Re-authen, nếu sai thì sẽ throw lỗi ngay, ko update đc
        try await user.reauthenticate(with: credential)

        // Nếu re-authen đc thì cập nhật pass
        try await user.updatePassword(to: newPass)
        
    }
    
    // Update information
    func updateInformation(username: String, newEmail: String) async throws {
            guard let user = Auth.auth().currentUser else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])
            }
            
            // Update Username
            if username != self.currentUser?.username {
                try await Firestore.firestore().collection("users").document(user.uid).updateData(["username": username])
            }
            
            // Update Email
            if newEmail != user.email {
                
                // Check trùng trong Firestore trước
                let querySnapshot = try await Firestore.firestore()
                    .collection("users")
                    .whereField("email", isEqualTo: newEmail)
                    .getDocuments()
                
                if !querySnapshot.documents.isEmpty {
                     throw NSError(domain: "AppError", code: 409, userInfo: [NSLocalizedDescriptionKey: "This email already existed"])
                }

                try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
                
                
                // Cập nhật Firestore (Hiển thị email mới luôn)
                try await Firestore.firestore().collection("users").document(user.uid).updateData(["email": newEmail])
                
                try logOut()
                
                throw NSError(domain: "Auth", code: 100, userInfo: [NSLocalizedDescriptionKey: "The verification email has been sent to \(newEmail). Please check your inbox and click confirm to complete the process."])
            }
            
            await fetchUser()
        }
    // Hàm cập nhật Avatar bằng tên ảnh có sẵn
    func updateAvatar(iconName: String) {
        guard let uid = self.userSession?.uid else { return }
        Firestore.firestore().collection("users").document(uid).updateData([
            "avatar": iconName
        ]) { error in
            if let error = error {
                print("AuthViewModel_1 \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.currentUser?.avatar = iconName
            }
            print("Đổi avatar thành công: \(iconName)")
        }
    }
}
