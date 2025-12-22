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
