//
//  EditGroupViewModel.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class EditGroupViewModel: ObservableObject {
    // Input từ màn trước
    let group: ChatGroup
    
    // UI State
    @Published var groupName: String
    @Published var allUsers: [User] = []
    @Published var currentMemberIds: [String]      // ID các thành viên đang ở trong nhóm
    @Published var selectedNewUserIds: Set<String> = [] // ID các thành viên mới được tick chọn thêm
    @Published var isSaving = false
    
    private let db = Firestore.firestore()
    
    init(group: ChatGroup) {
        self.group = group
        self.groupName = group.name
        self.currentMemberIds = group.members
        fetchUsers()
    }
    
    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    // Điều kiện enable nút Save:
    // Tên nhóm thay đổi hoặc có chọn thêm thành viên mới
    var canSave: Bool {
        let isNameChanged = groupName != group.name && !groupName.isEmpty
        let hasNewMembers = !selectedNewUserIds.isEmpty
        return isNameChanged || hasNewMembers
    }
    
    // Load user
    func fetchUsers() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            DispatchQueue.main.async {
                self.allUsers = documents.compactMap { doc -> User? in
                    if doc.documentID == currentUid { return nil } // Trừ mình
                    return User(dictionary: doc.data())
                }
            }
        }
    }
    
    // Checkbox chọn thành viên mới
    func toggleNewMemberSelection(userId: String) {
        if selectedNewUserIds.contains(userId) {
            selectedNewUserIds.remove(userId)
        } else {
            selectedNewUserIds.insert(userId)
        }
    }
    
    // Xoá thành viên hiện tại
    func removeMember(userId: String, userName: String) {
        db.collection("groups").document(group.id).updateData([
            "members": FieldValue.arrayRemove([userId])
        ]) { [weak self] error in
            if error == nil {
                guard let self = self else { return }
                
                // Gửi thông báo hệ thống
                self.sendSystemMessage("Admin removed \(userName) from the group.")
                
                DispatchQueue.main.async {
                    if let index = self.currentMemberIds.firstIndex(of: userId) {
                        self.currentMemberIds.remove(at: index)
                    }
                }
            }
        }
    }
    
    // Hàm Save
    func saveChanges(completion: @escaping (Bool) -> Void) {
        guard canSave else { return }
        self.isSaving = true
        
        var dataToUpdate: [String: Any] = [:]
        
        // Logic Đổi tên
        if groupName != group.name {
            dataToUpdate["name"] = groupName
            // Gửi tin nhắn hệ thống
            sendSystemMessage("Admin changed the group name to \"\(groupName)\"")
        }
        
        // Logic Thêm thành viên
        if !selectedNewUserIds.isEmpty {
            dataToUpdate["members"] = FieldValue.arrayUnion(Array(selectedNewUserIds))
            
            // Lấy tên các user mới được thêm để hiển thị
            let newMemberNames = allUsers
                .filter { selectedNewUserIds.contains($0.id) }
                .map { $0.username }
                .joined(separator: ", ")
            
            // Gửi tin nhắn hệ thống
            sendSystemMessage("Admin added \(newMemberNames) to the group.")
        }
        
        dataToUpdate["updatedAt"] = Timestamp(date: Date())
        
        db.collection("groups").document(group.id).updateData(dataToUpdate) { error in
            DispatchQueue.main.async {
                self.isSaving = false
                completion(error == nil)
            }
        }
    }
    
    // Gửi system mess
    private func sendSystemMessage(_ content: String) {
            guard let currentUid = Auth.auth().currentUser?.uid else { return }

            let messageData: [String: Any] = [
                "text": content,
                "type": "system",
                "userId": currentUid,
                "userName": "Admin",
                "timestamp": Timestamp(date: Date()),
                "userAvatarUrl": "",
                "photoWidth": 0,
                "photoHeight": 0
            ]
            
            // Lưu trên firétore
            db.collection("groups").document(group.id).collection("messages").addDocument(data: messageData)
            
            // Cập nhật recent mess
            db.collection("groups").document(group.id).updateData([
                "latestMessage": content,
                "updatedAt": Timestamp(date: Date())
            ])
        }
}
