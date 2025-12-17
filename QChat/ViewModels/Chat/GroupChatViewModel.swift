//
//  ChatViewModel.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ChatViewModel: ObservableObject {
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
                    self.currentUserAvatarUrl = avatarUrl // Lưu vào biến
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
                    print("ChatViewModel - Fetch Mess: \(error.localizedDescription)")
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
                    let typeRaw = data["type"] as? String ?? "text"
                    let type = MessageType(rawValue: typeRaw) ?? .text
                    let pWidth = data["photoWidth"] as? CGFloat
                    let pHeight = data["photoHeight"] as? CGFloat
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let userAvatarUrl = data["userAvatarUrl"] as? String ?? ""
                    
                    return Message(id: id, text: text, type: type, photoWidth: pWidth, photoHeight: pHeight, userId: userId, userName: userName, timestamp: timestamp, userAvatarUrl: userAvatarUrl)
                }
            }
    }
    
    // Hàm gửi Text
    func sendTextMessage() {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        performSendMessage(content: text, type: "text")
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
    private func performSendMessage(content: String, type: String, width: CGFloat = 0, height: CGFloat = 0) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "text": content,
            "type": type,
            "photoWidth": width,
            "photoHeight": height,
            "userId": currentUserID,
            "userName": currentUserName,
            "userAvatarUrl": self.currentUserAvatarUrl,
            "timestamp": Timestamp(date: Date())
            
        ]
        
        db.collection("messages").addDocument(data: data)
    }
}
