//
//  PCVM+Interactions.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension PrivateChatViewModel {
    
    // Reation
    func sendReaction(messageId: String, icon: String) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let fieldName = "reactions.\(currentUid)"
        
        Firestore.firestore().collection("chats").document(chatId).collection("messages").document(messageId)
            .updateData([fieldName: icon])
    }
    
    func cancelReaction(messageId: String) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let fieldName = "reactions.\(currentUid)"
        
        Firestore.firestore().collection("chats").document(chatId).collection("messages").document(messageId)
            .updateData([fieldName: FieldValue.delete()])
    }
    
    // Đã xem
    func markMessageAsRead(message: Message) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        if let readBy = message.readBy, readBy.contains(currentUid) { return }
        
        Firestore.firestore().collection("chats").document(chatId).collection("messages").document(message.id)
            .updateData([
                "readBy": FieldValue.arrayUnion([currentUid])
            ])
    }
    
    // Thu hồi
    func unsendMessage(message: Message) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        if message.userId != currentUid { return }
        
        // Update Message Detail
        Firestore.firestore().collection("chats").document(chatId).collection("messages").document(message.id)
            .updateData([
                "type": "unsent",
                "text": "Message has been unsent",
                "photoWidth": 0,
                "photoHeight": 0,
                "replyToId": FieldValue.delete(),
                "replyText": FieldValue.delete(),
                "replyUser": FieldValue.delete(),
                "reactions": FieldValue.delete()
            ]) { err in
                if let err = err { print("Unsend Error: \(err.localizedDescription)") }
            }
        
        // Update Recent Message
        updateRecentMessageAfterUnsend(
            text: "Message has been unsent",
            chatPartnerId: partner.id,
            currentUid: currentUid,
            unsentMessageId: message.id
        )
    }
    
    // Helper update recent
    func updateRecentMessageAfterUnsend(text: String, chatPartnerId: String, currentUid: String, unsentMessageId: String) {
        let recentRef = Firestore.firestore().collection("recent_messages")
            .document(currentUid).collection("messages").document(chatPartnerId)
        
        recentRef.getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let currentRecentId = data["messageId"] as? String {
                
                if currentRecentId == unsentMessageId {
                    let newData: [String: Any] = ["text": text]
                    
                    recentRef.updateData(newData)
                    
                    Firestore.firestore().collection("recent_messages")
                        .document(chatPartnerId).collection("messages").document(currentUid)
                        .updateData(newData)
                }
            }
        }
    }
}
