//
//  GCVM+Fetching.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension GroupChatViewModel {
    
    // Lắng nghe thay đổi của Group
    func listenToGroupUpdates() {
        db.collection("groups").document(self.groupId).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                if let name = data["name"] as? String {
                    self.groupName = name
                }
                self.pinnedMessageId = data["pinnedMessageId"] as? String
                self.pinnedMessageContent = data["pinnedMessageContent"] as? String
                if let updatedMembers = data["members"] as? [String] {
                    self.memberIds = updatedMembers
                }
                self.nickNames = data["nickNames"] as? [String:String] ?? [:]
            }
        }
    }
    
    // Lấy thông tin user hiện tại
    func fetchCurrentUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.currentUserName = data["username"] as? String ?? "Unknown"
                    self.currentUserAvatarUrl = data["avatar"] as? String ?? ""
                }
            }
        }
    }
    
    // Lấy danh sách tất cả user
    func fetchAllUsers() {
        db.collection("users").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            DispatchQueue.main.async {
                self.allUsers = documents.compactMap { doc -> User? in
                    return User(dictionary: doc.data())
                }
            }
        }
    }
    
    // Lấy và lắng nghe tin nhắn
    func fetchMessages() {
        db.collection("groups").document(self.groupId).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { querySnapshot, error in
                if let error = error { print("Fetch Error: \(error)"); return }
                
                guard let documents = querySnapshot?.documents else { return }
                
                self.messages = documents.compactMap { document -> Message? in
                    let data = document.data()
                    let id = document.documentID
                    
                    // Parsing
                    let text = data["text"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    let userName = data["userName"] as? String ?? "Unknown"
                    let type = MessageType(rawValue: data["type"] as? String ?? "text") ?? .text
                    let pWidth = data["photoWidth"] as? CGFloat
                    let pHeight = data["photoHeight"] as? CGFloat
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let userAvatarUrl = data["userAvatarUrl"] as? String ?? ""
                    let replyText = data["replyText"] as? String
                    let replyUser = data["replyUser"] as? String
                    let reactions = data["reactions"] as? [String: String]
                    let readBy = data["readBy"] as? [String]
                    
                    var pollData: Poll? = nil
                    if let pollDict = data["poll"] as? [String: Any], type == .poll {
                        let question = pollDict["question"] as? String ?? ""
                        let allowMultiple = pollDict["allowMultipleVotes"] as? Bool ?? false
                        var options: [PollOption] = []
                        if let optionsArray = pollDict["options"] as? [[String: Any]] {
                            for opt in optionsArray {
                                let optId = opt["id"] as? String ?? UUID().uuidString
                                let optText = opt["text"] as? String ?? ""
                                let voters = opt["voterIds"] as? [String] ?? []
                                options.append(PollOption(id: optId, text: optText, voterIds: voters))
                            }
                        }
                        pollData = Poll(question: question, options: options, allowMultipleVotes: allowMultiple)
                    }
                    
                    return Message(id: id, text: text, type: type, photoWidth: pWidth, photoHeight: pHeight, userId: userId, userName: userName, timestamp: timestamp, userAvatarUrl: userAvatarUrl, replyText: replyText, replyUser: replyUser, readBy: readBy, poll: pollData, reacts: reactions)
                }
            }
        subscribeToTypingStatus()
    }
    
    // Typing
    func subscribeToTypingStatus() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        typingListener = db.collection("groups").document(self.groupId).collection("typing")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let names = documents.compactMap { doc -> String? in
                    let data = doc.data()
                    if doc.documentID != currentUid && (data["isTyping"] as? Bool ?? false) {
                        return data["username"] as? String
                    }
                    return nil
                }
                
                DispatchQueue.main.async {
                    self.typingUserNames = names
                }
            }
    }
    
    // Gửi trạng thái typing
    func sendTypingStatus(isTyping: Bool) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        db.collection("groups").document(self.groupId).collection("typing")
            .document(currentUid)
            .setData(["isTyping": isTyping, "username": currentUserName], merge: true)
    }
    
    
    
}
