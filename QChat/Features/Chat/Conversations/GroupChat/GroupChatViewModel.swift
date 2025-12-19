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
    @Published var allUsers: [User] = []
    @Published var typingUserNames: [String] = []
    
    let groupId: String? // Lưu ID nhóm hiện tại
    
    private let db = Firestore.firestore()
    
    // Listen typing
    private var typingListener: ListenerRegistration?
    
    // Biến xác định đường dẫn
    private var messagesCollection: CollectionReference {
        if let id = groupId {
            // Đường dẫn cho nhóm riêng
            return db.collection("groups").document(id).collection("messages")
        } else {
            // Đường dẫn cho nhóm chung
            return db.collection("messages")
        }
    }
    
    init(groupId: String? = nil) {
        self.groupId = groupId
        fetchCurrentUserProfile()
        fetchMessages()
        fetchAllUsers()
    }
    
    // Hàm lắng nghe trạng thái gõ
    func subscribeToTypingStatus() {
        guard let gid = groupId else { return }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        typingListener = db.collection("groups").document(gid).collection("typing")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                // Lọc ra những người đang gõ (isTyping == true)
                let names = documents.compactMap { doc -> String? in
                    let data = doc.data()
                    let uid = doc.documentID
                    let isTyping = data["isTyping"] as? Bool ?? false
                    let username = data["username"] as? String ?? "Someone"
                    
                    // không phải là mình
                    if uid != currentUid && isTyping {
                        return username
                    }
                    return nil
                }
                
                DispatchQueue.main.async {
                    self.typingUserNames = names
                }
            }
    }
    
    // Gửi status đang typing
    func sendTypingStatus(isTyping: Bool) {
        guard let gid = groupId else { return }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "isTyping": isTyping,
            "username": currentUserName
        ]
        
        db.collection("groups").document(gid).collection("typing")
            .document(currentUid)
            .setData(data, merge: true)
    }
    
    // Lấy toàn bộ thành viên
    func fetchAllUsers() {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("GroupChatViewModel_0: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            DispatchQueue.main.async {
                self.allUsers = documents.compactMap { doc -> User? in
                    let data = doc.data()
                    let id = doc.documentID
                    let username = data["username"] as? String ?? "Unknown"
                    let email = data["email"] as? String ?? ""
                    let avatar = data["avatar"] as? String ?? ""
                    return User(id: id, email: email, username: username, avatar: avatar)
                }
            }
        }
    }
    
    //Lọc lấy danh sách ảnh từ tin nhắn
    var galleryMessages: [Message] {
        return messages.filter { $0.type == .image }
    }
    
    
    // Lấy thông tin user
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
    
    // Hàm Lấy tin nhắn
    func fetchMessages() {
        messagesCollection
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
                    
                    let readBy = data["readBy"] as? [String]
                    
                    return Message(id: id, text: text, type: type, photoWidth: pWidth, photoHeight: pHeight, userId: userId, userName: userName, timestamp: timestamp, userAvatarUrl: userAvatarUrl, replyText: replyText, replyUser: replyUser,readBy: readBy, reacts: reactions)
                }
            }
        subscribeToTypingStatus()
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
        
        if let reply = replyTo {
            data["replyToId"] = reply.id
            data["replyUser"] = reply.userName
            data["replyText"] = reply.type == .text ? reply.text : "[Media]"
        }
        
        // Gửi tin nhắn
        messagesCollection.addDocument(data: data)
        
        // Nếu là nhóm riêng,update tin nhắn cuối ra recent
        if let gid = groupId {
            let lastMsgPreview = type == "text" ? content : (type == "sticker" ? "[Sticker]" : "[Photo]")
            
            db.collection("groups").document(gid).updateData([
                "latestMessage": lastMsgPreview,
                "updatedAt": Timestamp(date: Date()) // Cập nhật thời gian để nhảy lên đầu
            ])
        }
    }
    
    // Hàm thả react
    func sendReaction(messageId: String, icon: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let fieldName = "reactions.\(currentUserID)"
        
        messagesCollection.document(messageId).updateData([fieldName: icon])
        { err in
            if let err = err { print("GroupChatViewModel_3: \(err)") }
        }
    }
    
    // Hàm xoá react
    func cancelReaction(messageId: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let fieldName = "reactions.\(currentUserID)"
        
        messagesCollection.document(messageId).updateData([fieldName: FieldValue.delete()])
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
        messagesCollection.document(message.id).updateData([
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
    // Đánh dấu tin nhắn đã đọc
    func markMessageAsRead(message: Message) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        // Đọc rồi thì thôi
        if let readBy = message.readBy, readBy.contains(currentUid) {
            return
        }
        
        // Cập nhật lên Firestore
        messagesCollection
            .document(message.id)
            .updateData([
                "readBy": FieldValue.arrayUnion([currentUid])
            ]) { error in
                if let error = error {
                    print("GroupChatViewModel_6: \(error.localizedDescription)")
                }
            }
    }
}
