//
//  NewMessageViewModel.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class NewMessageViewModel: ObservableObject {
    @Published var users = [User]()
    
    init() {
        fetchUsers()
    }
    
    func fetchUsers() {
        
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        // Lên Firestore lấy toàn bộ bảng "users"
        Firestore.firestore().collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error get list user: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            // Map dữ liệu về mảng User , compactMap = ko lấy nil
            self.users = documents.compactMap({ try? $0.data(as: User.self) })
                .filter({ $0.id != currentUid }) // lọc chính mình
        }
    }
}
