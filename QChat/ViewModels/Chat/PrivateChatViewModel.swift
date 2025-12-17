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
    let user : User
    
    init(user : User){
        self.user = user
        fetchMessage()
        fetchCurrentUserProfile()
    }
    
    //Load tin nhắn
    func fetchMessage() {
        guard let currentId = Auth.auth().currentUser?.uid else { return }
        
        let chatId = ChatService.getChatId(fromId: currentId, toId: user.id)
        
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
                    
                    return Message(id: id, text: text, type: type, photoWidth: pWidth, photoHeight: pHeight, userId: userId, userName: userName, timestamp: timestamp)
                }
            }
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
    func sendTextMessage() {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        performSendMessage(content: text, type: "text")
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
    private func performSendMessage(content: String, type: String, width: CGFloat = 0, height: CGFloat = 0) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let chatId = ChatService.getChatId(fromId: currentUid, toId: user.id)
        let chatPartnerId = user.id
        
        // Data lưu vào Message Detail
        let data: [String: Any] = [
            "text": content,
            "type": type,
            "photoWidth": width,
            "photoHeight": height,
            "userId": currentUid,
            "userName": currentUserName,
            "timestamp": Timestamp(date: Date())
        ]
        
        Firestore.firestore().collection("chats").document(chatId).collection("messages").addDocument(data: data)
        
        // Data lưu vào Recent Message (List chat bên ngoài)
        var recentText = content
        if type == "sticker" { recentText = "[Nhãn dán]" }
        if type == "image" { recentText = "[Hình ảnh]" }
        
        let recentMsgData: [String: Any] = [
            "text": recentText,
            "fromId": currentUid,
            "toId": chatPartnerId,
            "timestamp": Timestamp(date: Date())
        ]
        
        Firestore.firestore().collection("recent_messages").document(currentUid).collection("messages").document(chatPartnerId).setData(recentMsgData)
        Firestore.firestore().collection("recent_messages").document(chatPartnerId).collection("messages").document(currentUid).setData(recentMsgData)
    }
}
