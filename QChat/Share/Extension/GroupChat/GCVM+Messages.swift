//
//  GroupChatViewModel+Messaging.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

extension GroupChatViewModel {
    
    // Hàm gửi Text
    func sendTextMessage(replyTo: Message? = nil) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        performSendMessage(content: text, type: "text", replyTo: replyTo, lastestMessage: text)
        self.text = ""
    }
    
    // Hàm gửi Sticker
    func sendSticker(stickerName: String) {
        performSendMessage(content: stickerName, type: "sticker", lastestMessage: "[Sticker]")
    }
    
    // Hàm gửi ảnh
    func sendImage(name: String, width: CGFloat, height: CGFloat){
        performSendMessage(content: name, type: "image", width: width, height: height, lastestMessage: "[Photo]")
    }
    
    // Hàm xử lý chung
    func performSendMessage(content: String, type: String, width: CGFloat = 0, height: CGFloat = 0, replyTo: Message? = nil, lastestMessage: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        var data: [String: Any] = [
            "text": content,
            "type": type,
            "photoWidth": width,
            "photoHeight": height,
            "userId": currentUserID,
            "userName": currentUserName,
            "userAvatarUrl": self.currentUserAvatarUrl,
            "timestamp": Timestamp(date: Date()),
            "readBy" : [currentUserID]
        ]
        
        let latestMessageData: [String: Any] = [
            "text": lastestMessage,
            "fromId": currentUserID,
            "timestamp": Timestamp(),
            "readBy": [currentUserID]
        ]
        
        if let reply = replyTo {
            data["replyToId"] = reply.id
            data["replyUser"] = reply.userName
            data["replyText"] = reply.type == .text ? reply.text : "[Media]"
        }
        
        // Gửi tin nhắn
        db.collection("groups").document(self.groupId).collection("messages").addDocument(data: data)
        
        // Update recent mess
        db.collection("groups").document(self.groupId).updateData([
            "latestMessage": latestMessageData,
            "updatedAt": Timestamp(date: Date())
        ])
    }
}
