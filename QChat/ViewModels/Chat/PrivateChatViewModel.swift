//
//  PrivateChatViewModel.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class PrivateChatViewModel : ObservableObject{
    @Published var messages = [Message]()
    @Published var text = ""
    @Published var currentUserName : String = "Unknow"
    
    @Published var isPartnerTyping : Bool = false
    let partner : User

    
    // Listen typing
    private var typingListener: ListenerRegistration?
    
    init(partner : User){
        self.partner = partner
        fetchMessage()
        fetchCurrentUserProfile()
    }
    
    var chatId : String {
        guard let currentUid = Auth.auth().currentUser?.uid else { return ""}
        return ChatService.getChatId(fromId: currentUid, toId: partner.id)
    }
    
    // Hàm lắng nghe trạng thái gõ
    func subscribeToTypingStatus() {
        guard (Auth.auth().currentUser?.uid) != nil else { return }

        typingListener = Firestore.firestore().collection("chats").document(chatId).collection("typing").document(partner.id)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else {
                    // Nếu không có data -> chưa gõ lần nào
                    DispatchQueue.main.async { self.isPartnerTyping = false }
                    return
                }
                let isTyping = data["isTyping"] as? Bool ?? false
                
                DispatchQueue.main.async {
                    self.isPartnerTyping = isTyping
                }
            }
    }
    
    // Gửi trạng thái
    func sendTypingStatus (isTyping : Bool){
        guard let currentId = Auth.auth().currentUser?.uid else {return}
        let data: [String : Any] = ["isTyping" : isTyping]
        
        Firestore.firestore().collection("chats").document(chatId).collection("typing").document(currentId)
            .setData(data, merge: true)
    }
    
    
    //Load tin nhắn
    func fetchMessage() {
        guard (Auth.auth().currentUser?.uid) != nil else { return }
        
        Firestore.firestore().collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("PrivateChatViewModel_1: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("PrivateChatViewModel_2")
                    return
                }
                
                self.messages = documents.compactMap { document -> Message? in
                    let data = document.data()
                    let id = document.documentID
                    let text = data["text"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    let userName = data["userName"] as? String ?? "Unknown"
                    let typeRaw = data["type"] as? String ?? "text"
                    let type = MessageType(rawValue: typeRaw) ?? .text
                    let pWidth = data["photoWidth"] as? CGFloat
                    let pHeight = data["photoHeight"] as? CGFloat
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    
                    let replyText = data["replyText"] as? String
                    let replyUser = data["replyUser"] as? String
                    let reactions = data["reactions"] as? [String: String]
                    
                    let readBy = data["readBy"] as? [String]
                        
                    return Message(id: id, text: text, type: type, photoWidth: pWidth, photoHeight: pHeight, userId: userId, userName: userName, timestamp: timestamp, replyText: replyText, replyUser: replyUser,readBy: readBy ,reacts: reactions)
                }
            }
        subscribeToTypingStatus()
    }
    
    // Load tên của mình để gửi kèm khi gửi tin nhăns mới
    func fetchCurrentUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let name = data["username"] as? String {
                DispatchQueue.main.async {
                    self.currentUserName = name
                }
            }
        }
    }
    
    // Hàm gửi Text
    func sendTextMessage(replyTo: Message? = nil) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        performSendMessage(content: text, type: "text", replyTo: replyTo)
        self.text = ""
    }
    
    // Hàm gửi Sticker (Nhận tên sticker)
    func sendSticker(stickerName: String) {
        performSendMessage(content: stickerName, type: "sticker")
    }
    
    // Hàm gửi ảnh
    func sendImage(name: String, width: CGFloat, height: CGFloat){
        performSendMessage(content: name, type: "image", width: width, height: height)
    }
    
    // Hàm xử lý logic chung để đẩy lên Firebase
    private func performSendMessage(content: String, type: String, width: CGFloat = 0, height: CGFloat = 0,replyTo: Message? = nil) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let chatId = ChatService.getChatId(fromId: currentUid, toId: partner.id)
        let chatPartnerId = partner.id
        // Lấy id message
        let msgRef = Firestore.firestore().collection("chats").document(chatId).collection("messages").document()
        let messageId = msgRef.documentID
        
        // Data lưu vào Message Detail
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
        
        // Data lưu vào Recent Message
        var recentText = content
        if type == "sticker" { recentText = "[Sticker]" }
        if type == "image" { recentText = "[Photo]" }
        
        let recentMsgData: [String: Any] = [
            "text": recentText,
            "fromId": currentUid,
            "toId": chatPartnerId,
            "timestamp": Timestamp(date: Date()),
            "messageId": messageId
        ]
        
        // Lưu vào recent để cả 2 cùng hiện
        Firestore.firestore().collection("recent_messages").document(currentUid).collection("messages").document(chatPartnerId).setData(recentMsgData)
        Firestore.firestore().collection("recent_messages").document(chatPartnerId).collection("messages").document(currentUid).setData(recentMsgData)
    }
    
    // Hàm thả react
    func sendReaction(messageId: String, icon: String) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let chatId = ChatService.getChatId(fromId: currentUid, toId: partner.id)
        
        let fieldName = "reactions.\(currentUid)"
        
        Firestore.firestore().collection("chats")
            .document(chatId)
            .collection("messages")
            .document(messageId)
            .updateData([fieldName: icon])
    }
    
    // Hàm xoá react
    func cancelReaction(messageId: String) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let chatId = ChatService.getChatId(fromId: currentUid, toId: partner.id)
        
        let fieldName = "reactions.\(currentUid)"
        
        Firestore.firestore().collection("chats")
            .document(chatId)
            .collection("messages")
            .document(messageId)
            .updateData([fieldName: FieldValue.delete()])
    }
    
    // Hàm thu hồi tin nhắn
    func unsendMessage(message: Message) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        // Chỉ được xoá tin của mình
        if message.userId != currentUid { return }
        
        // Lấy Chat ID
        let chatId = ChatService.getChatId(fromId: currentUid, toId: partner.id)
        
        // Thực hiện update lên Firestore
        Firestore.firestore().collection("chats")
            .document(chatId)
            .collection("messages")
            .document(message.id)
            .updateData([
                "type": "unsent",                    // Đổi loại tin nhắn
                "text": "Message has been unsent",     // Đổi nội dung
                "photoWidth": 0,                     // Reset kích thước ảnh
                "photoHeight": 0,
                // Xoá các trường không cần thiết
                "replyToId": FieldValue.delete(),
                "replyText": FieldValue.delete(),
                "replyUser": FieldValue.delete(),
                "reactions": FieldValue.delete()
            ]) { err in
                if let err = err {
                    print("PrivateChatViewModel_3: \(err.localizedDescription)")
                }
            }
        
        // Cập nhật recent nếu là tnhan cuối
        updateRecentMessageAfterUnsend(
                text: "Message has been unsent",
                chatPartnerId: partner.id,
                currentUid: currentUid,
                unsentMessageId: message.id 
            )
    }
    
    // Hàm phụ trợ để cập nhật Recent Message
    
    private func updateRecentMessageAfterUnsend(text: String, chatPartnerId: String, currentUid: String, unsentMessageId: String) {
        
        let recentRef = Firestore.firestore().collection("recent_messages")
            .document(currentUid).collection("messages").document(chatPartnerId)
        
        // Đọc tin nhắn gần nhất hiện tại
        recentRef.getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let currentRecentId = data["messageId"] as? String {
                
                // Nếu ID trùng khớp thì đây chính là tin nhắn vừa thu hồi
                if currentRecentId == unsentMessageId {
                    let newData: [String: Any] = [
                        "text": text,
                    ]
                    
                    // Cập nhật cho mình
                    recentRef.updateData(newData)
                    
                    // Cập nhật cho đối phương
                    Firestore.firestore().collection("recent_messages")
                        .document(chatPartnerId).collection("messages").document(currentUid)
                        .updateData(newData)
                }
            }
        }
    }
    
    // Đánh dấu tin nhắn này đã đọc
    func markMessageAsRead(message: Message) {
            guard let currentUid = Auth.auth().currentUser?.uid else { return }
            
            // Nếu mình đã có trong danh sách 'readBy' rồi thì thôi
            if let readBy = message.readBy, readBy.contains(currentUid) {
                return
            }
            
            // Cập nhật lên Firestore
            let chatId = ChatService.getChatId(fromId: currentUid, toId: partner.id)
            
            Firestore.firestore().collection("chats")
                .document(chatId)
                .collection("messages")
                .document(message.id)
                .updateData([
                    "readBy": FieldValue.arrayUnion([currentUid]) // Thêm ID mình vào mảng
                ])
        }
    
}
