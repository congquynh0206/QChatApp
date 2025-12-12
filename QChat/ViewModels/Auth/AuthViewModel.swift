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
        //self.userSession = Auth.auth().currentUser
        Task{
            await fetchUser()
        }
    }
    func fetchUser() async{
        guard let userId = Auth.auth().currentUser?.uid else {return }
        guard let snapshot = try? await Firestore .firestore().collection("users").document(userId).getDocument() else {return}
        guard let data = snapshot.data() else {return}
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
}
