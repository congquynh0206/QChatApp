//
//  GCVM+Interactions.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

extension GroupChatViewModel {
    
    // Reaction
    func sendReaction(messageId: String, icon: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let fieldName = "reactions.\(currentUserID)"
        
        db.collection("groups").document(self.groupId).collection("messages").document(messageId).updateData([fieldName: icon]) { err in
            if let err = err { print("Reaction Error: \(err)") }
        }
    }
    
    func cancelReaction(messageId: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let fieldName = "reactions.\(currentUserID)"
        
        db.collection("groups").document(self.groupId).collection("messages").document(messageId).updateData([fieldName: FieldValue.delete()]) { err in
            if let err = err { print("Cancel Reaction Error: \(err)") }
        }
    }
    
    // Thu hồi
    func unsendMessage(message: Message) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        if message.userId != currentUid { return }

        db.collection("groups").document(self.groupId).collection("messages").document(message.id).updateData([
            "type": "unsent",
            "text": "Message has been unsent",
            "photoWidth": 0,
            "photoHeight": 0,
            "replyToId": FieldValue.delete(),
            "replyText": FieldValue.delete(),
            "replyUser": FieldValue.delete(),
            "reactions": FieldValue.delete()
        ])
        
        updateGroupLatestMessageAfterUnsend(unsentMessage: message)
    }
    
    // Helper cập nhật latestMessage
    func updateGroupLatestMessageAfterUnsend(unsentMessage: Message) {
        let groupRef = db.collection("groups").document(groupId)
        
        groupRef.getDocument { snapshot, error in
            // Lấy dữ liệu latestMessage hiện tại từ Firebase
            if let data = snapshot?.data(),
               let latestMsgData = data["latestMessage"] as? [String: Any] {
                
                // Lấy timestamp của latest message
                let latestTimestamp = (latestMsgData["timestamp"] as? Timestamp)?.dateValue()
                
                // So sánh timestamp
                if let latestDate = latestTimestamp,
                   abs(latestDate.timeIntervalSince(unsentMessage.timestamp)) < 0.1 { // Chênh lệch < 0.1 giây

                    groupRef.updateData([
                        "latestMessage.text": "Message has been unsent"
                    ])
                }
            }
        }
    }
    // Đã xem
    func markMessageAsRead(message: Message) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        if let readBy = message.readBy, readBy.contains(currentUid) { return }
        
        db.collection("groups").document(self.groupId).collection("messages").document(message.id).updateData([
            "readBy": FieldValue.arrayUnion([currentUid])
        ])
    }
    
    // Ghim tin nhắn
    func pinMessage(message: Message) {
        var previewContent = ""
        switch message.type {
        case .text, .system: previewContent = message.text
        case .image: previewContent = "[Photo]"
        case .sticker: previewContent = "[Sticker]"
        default: return
        }
        
        db.collection("groups").document(self.groupId).updateData([
            "pinnedMessageId": message.id,
            "pinnedMessageContent": previewContent
        ])
    }
    
    func unpinMessage() {
        db.collection("groups").document(self.groupId).updateData([
            "pinnedMessageId": FieldValue.delete(),
            "pinnedMessageContent": FieldValue.delete()
        ])
    }
}
