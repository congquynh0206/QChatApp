//
//  PCVM+Messages.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension PrivateChatViewModel {
    
    // Hàm gửi Text
    func sendTextMessage(replyTo: Message? = nil) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        performSendMessage(content: text, type: "text", replyTo: replyTo)
        self.text = ""
    }
    
    // Hàm gửi Sticker
    func sendSticker(stickerName: String) {
        performSendMessage(content: stickerName, type: "sticker")
    }
    
    // Hàm gửi ảnh
    func sendImage(name: String, width: CGFloat, height: CGFloat) {
        performSendMessage(content: name, type: "image", width: width, height: height)
    }
    
    // Hàm xử lý logic chung
    func performSendMessage(content: String, type: String, width: CGFloat = 0, height: CGFloat = 0, replyTo: Message? = nil) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        // Lưu vào Message Detail
        let msgRef = Firestore.firestore().collection("chats").document(chatId).collection("messages").document()
        let messageId = msgRef.documentID
        
        var data: [String: Any] = [
            "id": messageId,
            "text": content,
            "type": type,
            "photoWidth": width,
            "photoHeight": height,
            "userId": currentUid,
            "userName": currentUserName,
            "timestamp": Timestamp(date: Date())
        ]
        
        if let reply = replyTo {
            data["replyToId"] = reply.id
            data["replyUser"] = reply.userName
            data["replyText"] = reply.type == .text ? reply.text : "[Media]"
        }
        
        msgRef.setData(data)
        
        // Lưu vào Recent Message
        var recentText = content
        if type == "sticker" { recentText = "[Sticker]" }
        if type == "image" { recentText = "[Photo]" }
        
        let recentMsgData: [String: Any] = [
            "text": recentText,
            "fromId": currentUid,
            "toId": partner.id,
            "timestamp": Timestamp(date: Date()),
            "messageId": messageId,
            "readBy" : [currentUid]
        ]
        
        // Update cho cả 2 bên
        Firestore.firestore().collection("recent_messages").document(currentUid).collection("messages").document(partner.id).setData(recentMsgData)
        Firestore.firestore().collection("recent_messages").document(partner.id).collection("messages").document(currentUid).setData(recentMsgData)
    }
}
