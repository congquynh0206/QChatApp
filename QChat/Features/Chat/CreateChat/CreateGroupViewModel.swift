//
//  CreateGroupViewModel.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class CreateGroupViewModel: ObservableObject {
    @Published var users: [User] = []           // Danh sách user để chọn
    @Published var selectedUserIds: Set<String> = [] // Các user đã được tick chọn
    @Published var groupName: String = ""
    @Published var isSaving = false
    
    private let db = Firestore.firestore()
    
    init() {
        fetchUsers()
    }
    
    // Lấy danh sách user
    func fetchUsers() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            DispatchQueue.main.async {
                self.users = documents.compactMap { doc -> User? in
                    if doc.documentID == currentUid { return nil } // trừ mình
                    return User(dictionary: doc.data())
                }
            }
        }
    }
    
    // Xử lý chọn/bỏ chọn
    func toggleSelection(user: User) {
        if selectedUserIds.contains(user.id) {
            selectedUserIds.remove(user.id)
        } else {
            selectedUserIds.insert(user.id)
        }
    }
    
    // Lưu nhóm lên Firebase
    func createGroup(completion: @escaping (ChatGroup?) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid, !groupName.isEmpty, !selectedUserIds.isEmpty else { return }
        
        self.isSaving = true
        let newGroupId = UUID().uuidString
        
        // Thêm chính mình vào danh sách thành viên
        var finalMembers = Array(selectedUserIds)
        finalMembers.append(currentUserID)
        
        let initialMessage = GroupLatestMessage(
            text: "New group",
            fromId: currentUserID,
            timestamp: Date(),
            readBy: [currentUserID]
        )
        
        let newGroup = ChatGroup(
            id: newGroupId,
            name: groupName,
            avatarUrl: "group-avatar",
            adminId: currentUserID,
            members: finalMembers,
            latestMessage: initialMessage,
            updatedAt: Date()
        )
        
        // Lưu
        db.collection("groups").document(newGroupId).setData(newGroup.dictionary) { error in
            DispatchQueue.main.async {
                self.isSaving = false
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(newGroup)
                }
            }
        }
    }
}
