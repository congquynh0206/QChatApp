//
//  PCVM+Fetching.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension PrivateChatViewModel {
    
    // Lấy tin nhắn realtime
    func fetchMessage() {
        guard (Auth.auth().currentUser?.uid) != nil else { return }
        
        Firestore.firestore().collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Fetch Message Error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.messages = documents.compactMap { document -> Message? in
                    let data = document.data()
                    let id = document.documentID
                    let text = data["text"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    let userName = data["userName"] as? String ?? "Unknown"
                    let type = MessageType(rawValue: data["type"] as? String ?? "text") ?? .text
                    let pWidth = data["photoWidth"] as? CGFloat
                    let pHeight = data["photoHeight"] as? CGFloat
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let replyText = data["replyText"] as? String
                    let replyUser = data["replyUser"] as? String
                    let reactions = data["reactions"] as? [String: String]
                    let readBy = data["readBy"] as? [String]
                        
                    return Message(id: id, text: text, type: type, photoWidth: pWidth, photoHeight: pHeight, userId: userId, userName: userName, timestamp: timestamp, replyText: replyText, replyUser: replyUser, readBy: readBy, reacts: reactions)
                }
            }
        subscribeToTypingStatus()
    }
    
    // Lấy tên mình
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
    
    // Typing
    func subscribeToTypingStatus() {
        guard (Auth.auth().currentUser?.uid) != nil else { return }

        typingListener = Firestore.firestore().collection("chats").document(chatId).collection("typing").document(partner.id)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else {
                    DispatchQueue.main.async { self.isPartnerTyping = false }
                    return
                }
                let isTyping = data["isTyping"] as? Bool ?? false
                
                DispatchQueue.main.async {
                    self.isPartnerTyping = isTyping
                }
            }
    }
    
    // Gửi trạng thái typing
    func sendTypingStatus(isTyping: Bool) {
        guard let currentId = Auth.auth().currentUser?.uid else { return }
        let data: [String : Any] = ["isTyping" : isTyping]
        
        Firestore.firestore().collection("chats").document(chatId).collection("typing").document(currentId)
            .setData(data, merge: true)
    }
}
