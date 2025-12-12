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
            
            // debug
            print("Đang lấy tin nhắn từ ChatID: \(chatId)")
            
            Firestore.firestore().collection("chats")
                .document(chatId)
                .collection("messages")
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Lỗi load tin nhắn: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("Không tìm thấy documents nào")
                        return
                    }
                    
                    print("Tìm thấy \(documents.count) tin nhắn") // Debug số lượng
                    
                    self.messages = documents.compactMap { document -> Message? in
                        let data = document.data()
                        let id = document.documentID
                        let text = data["text"] as? String ?? ""
                        let userId = data["userId"] as? String ?? ""
                        let userName = data["userName"] as? String ?? "Unknown"
                        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()

                        return Message(id: id, text: text, userId: userId, userName: userName, timestamp: timestamp)
                    }
                }
        }
    
    // Load tên của mình
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
    
    // Hàm gửi tin nhắn
    func sendMessage() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        if text.isEmpty { return }
        let chatPartnerId = user.id
        
        
        let chatId = ChatService.getChatId(fromId: currentUid, toId: user.id)
        let data: [String: Any] = [
            "text": text,
            "userId": currentUid,
            "userName": currentUserName,
            "timestamp": Timestamp(date: Date())
        ]
        
        Firestore.firestore().collection("chats")
            .document(chatId)
            .collection("messages")
            .addDocument(data: data) { error in
                if let error = error {
                    print("Error sending private: \(error.localizedDescription)")
                }
            }
        let recentMsgData: [String: Any] = [
            "text": text,
            "fromId": currentUid,
            "toId": chatPartnerId,
            "timestamp": Timestamp(date: Date())
        ]
        
        // Lưu cho bản thân mình
        Firestore.firestore().collection("recent_messages")
            .document(currentUid)
            .collection("messages")
            .document(chatPartnerId) // Dùng ID người kia làm ID document để không bị trùng
            .setData(recentMsgData)
        
        // Lưu cho người kia (Partner) - Để máy họ cũng hiện tin nhắn mới nhất
        Firestore.firestore().collection("recent_messages")
            .document(chatPartnerId)
            .collection("messages")
            .document(currentUid)
            .setData(recentMsgData)
        self.text = ""
        
    }
}
