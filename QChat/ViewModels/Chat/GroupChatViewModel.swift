//
//  ChatViewModel.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class GroupChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var text: String = ""
    @Published var currentUserName: String = "Unknown"
    @Published var currentUserAvatarUrl: String = ""
    
    // Khởi tạo database
    private let db = Firestore.firestore()
    
    init() {
        fetchCurrentUserProfile()
        fetchMessages()
    }
    
    func fetchCurrentUserProfile() {
        // Lấy ID người dùng đang đăng nhập
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Tìm tên trong bảng user
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("GroupChatViewModel_1: \(error.localizedDescription)")
                return
            }
            
            // Lấy dữ liệu về
            if let data = snapshot?.data() {
                let name = data["username"] as? String ?? "Unknown"
                let avatarUrl = data["avatar"] as? String ?? ""
                
                DispatchQueue.main.async {
                    self.currentUserName = name
                    self.currentUserAvatarUrl = avatarUrl
                }
            }
        }
    }
    
    // Hàm Lấy tin nhắn (Real-time)
    func fetchMessages() {
        db.collection("messages")
            .order(by: "timestamp", descending: false) // Sắp xếp tin nhắn cũ trên, mới dưới
            .addSnapshotListener { querySnapshot, error in
                // Nếu có lỗi thì thoát
                if let error = error {
                    print("GroupChatViewModel_2: \(error.localizedDescription)")
                    return
                }
                
                // Lấy dữ liệu về và chuyển thành mảng Message
                guard let documents = querySnapshot?.documents else { return }
                
                // Dùng map để chuyển đổi từ dữ liệu Firebase sang Model Message
                self.messages = documents.compactMap { document -> Message? in
                    let data = document.data()
                    let id = document.documentID
                    let text = data["text"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    let userName = data["userName"] as? String ?? "Unknown"
                    let typeRaw = data["type"] as? String ?? "text"             // để đổi từ text sang enum
                    let type = MessageType(rawValue: typeRaw) ?? .text
                    let pWidth = data["photoWidth"] as? CGFloat
                    let pHeight = data["photoHeight"] as? CGFloat
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let userAvatarUrl = data["userAvatarUrl"] as? String ?? ""
                    let replyText = data["replyText"] as? String
                    let replyUser = data["replyUser"] as? String
                    let reactions = data["reactions"] as? [String: String]
                    
                    return Message(id: id, text: text, type: type, photoWidth: pWidth, photoHeight: pHeight, userId: userId, userName: userName, timestamp: timestamp, userAvatarUrl: userAvatarUrl, replyText: replyText, replyUser: replyUser, reacts: reactions)
                }
            }
    }
    
    // Hàm gửi Text
    func sendTextMessage(replyTo: Message? = nil) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return } //trim()
        performSendMessage(content: text, type: "text", replyTo: replyTo)
        self.text = ""
    }
    
    // Hàm gửi Sticker
    func sendSticker(stickerName: String) {
        performSendMessage(content: stickerName, type: "sticker")
    }
    // Hàm gửi ảnh
    func sendImage(name: String, width: CGFloat, height: CGFloat){
        performSendMessage(content: name, type: "image", width: width, height: height)
    }
    
    // Hàm xử lý chung
    private func performSendMessage(content: String, type: String, width: CGFloat = 0, height: CGFloat = 0, replyTo: Message? = nil) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        var data: [String: Any] = [
            "text": content,
            "type": type,
            "photoWidth": width,
            "photoHeight": height,
            "userId": currentUserID,
            "userName": currentUserName,
            "userAvatarUrl": self.currentUserAvatarUrl,
            "timestamp": Timestamp(date: Date())
        ]
        
        // Nếu có reply thì lưu thêm vào data
        if let reply = replyTo {
            data["replyToId"] = reply.id
            data["replyUser"] = reply.userName
            data["replyText"] = reply.type == .text ? reply.text : "[Media]"
        }
        
        db.collection("messages").addDocument(data: data)
    }
    
    // Hàm thả react
    func sendReaction(messageId: String, icon: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let fieldName = "reactions.\(currentUserID)"
        
        db.collection("messages").document(messageId).updateData([fieldName: icon])
        { err in
            if let err = err { print("GroupChatViewModel_3: \(err)") }
        }
    }
    
    // Hàm xoá react
    func cancelReaction(messageId: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let fieldName = "reactions.\(currentUserID)"
        
        db.collection("messages").document(messageId).updateData([fieldName: FieldValue.delete()])
        { err in
            if let err = err { print("GroupChatViewModel_4: \(err)") }
        }
    }

    // Hàm thu hồi
    func unsendMessage(message: Message) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        // Chỉ cho phép thu hồi tin nhắn của mình
        if message.userId != currentUid { return }
        
        // Đổi type sang 'unsent' và xóa nội dung
        db.collection("messages").document(message.id).updateData([
            "type": "unsent",
            "text": "Message has been unsent",
            "photoWidth": 0,
            "photoHeight": 0,
            "replyToId": FieldValue.delete(),
            "replyText": FieldValue.delete(),
            "replyUser": FieldValue.delete(),
            "reactions": FieldValue.delete()
        ]) { err in
            if let err = err { print("GroupChatViewModel_5: \(err)") }
        }
    }
}
