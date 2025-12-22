//
//  GCVM+Management.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension GroupChatViewModel {
    
    // Gán admin cho ngkhac
    func transferAdminRights(to userId: String, name: String, completion: @escaping (Bool) -> Void) {
        db.collection("groups").document(groupId).updateData([
            "adminId": userId
        ]) { error in
            if let error = error {
                print("Error transfer admin: \(error)")
                completion(false)
            } else {
                let msgContent = "Admin rights transferred to \(name)"
                self.performSendMessage(content: msgContent, type: "system", lastestMessage: msgContent)
                completion(true)
            }
        }
    }
    
    // Rời nhóm
    func leaveGroup(completion: @escaping (Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("groups").document(groupId).updateData([
            "members": FieldValue.arrayRemove([currentUid])
        ]) { error in
            if let error = error {
                print("Error leaving group: \(error)")
                completion(false)
            } else {
                self.performSendMessage(content: "\(self.currentUserName) left the group", type: "system", lastestMessage: "\(self.currentUserName) left the group.")
                completion(true)
            }
        }
    }
    
    // Xoá nhóm
    func deleteGroup(completion: @escaping (Bool) -> Void) {
        let groupRef = db.collection("groups").document(groupId)
        let batch = db.batch()
        let dispatchGroup = DispatchGroup()
        var fetchError: Error?
        
        // Delete Messages
        dispatchGroup.enter()
        groupRef.collection("messages").getDocuments { snapshot, error in
            if let error = error { fetchError = error }
            snapshot?.documents.forEach { batch.deleteDocument($0.reference) }
            dispatchGroup.leave()
        }
        
        // Delete Typing Status
        dispatchGroup.enter()
        groupRef.collection("typing").getDocuments { snapshot, error in
            if let error = error { fetchError = error }
            snapshot?.documents.forEach { batch.deleteDocument($0.reference) }
            dispatchGroup.leave()
        }
        
        // Commit
        dispatchGroup.notify(queue: .main) {
            if let error = fetchError {
                print("Error fetching sub-collections: \(error)")
                completion(false)
                return
            }
            batch.deleteDocument(groupRef)
            batch.commit { error in
                completion(error == nil)
            }
        }
    }
}
