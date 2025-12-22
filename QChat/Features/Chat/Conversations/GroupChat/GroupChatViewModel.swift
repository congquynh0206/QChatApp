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
    
    @Published var pinnedMessageId: String? = nil
    @Published var pinnedMessageContent: String? = nil
    
    @Published var memberIds: [String] = []
    
    
    let groupId: String // Lưu ID nhóm hiện tại
    
    private let db = Firestore.firestore()
    
    // Listen typing
    private var typingListener: ListenerRegistration?
    
    init(groupId: String , initialMemberIds: [String] = []) {
        self.groupId = groupId
        self.memberIds = initialMemberIds
        fetchCurrentUserProfile()
        fetchMessages()
        fetchAllUsers()
        listenToGroupUpdates()
    }
    
    // Hàm lănggs nghe để thay đổi
    func listenToGroupUpdates() {
        db.collection("groups").document(self.groupId).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                // Cập nhật state ghim
                self.pinnedMessageId = data["pinnedMessageId"] as? String
                self.pinnedMessageContent = data["pinnedMessageContent"] as? String
                if let updatedMembers = data["members"] as? [String] {
                    self.memberIds = updatedMembers
                }
            }
        }
    }
    
    // Hàm Ghim tin nhắn
    func pinMessage(message: Message) {
        // Xác định nội dung hiển thị text hoặc photo
        var previewContent = ""
        switch message.type {
        case .text, .system: previewContent = message.text
        case .image: previewContent = "[Photo]"
        case .sticker: previewContent = "[Sticker]"
        case .unsent: return
        case .poll : return
        }
        
        let data: [String: Any] = [
            "pinnedMessageId": message.id,
            "pinnedMessageContent": previewContent
        ]
        
        db.collection("groups").document(self.groupId).updateData(data)
    }
    
    // Hàm Gỡ ghim
    func unpinMessage() {
        
        let data: [String: Any] = [
            "pinnedMessageId": FieldValue.delete(),
            "pinnedMessageContent": FieldValue.delete()
        ]
        
        db.collection("groups")
            .document(self.groupId)
            .updateData(data)
    }
    
    
    // Hàm lắng nghe trạng thái gõ
    func subscribeToTypingStatus() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        typingListener = db.collection("groups").document(self.groupId).collection("typing")
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
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "isTyping": isTyping,
            "username": currentUserName
        ]
        
        db.collection("groups").document(self.groupId).collection("typing")
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
        db.collection("groups").document(self.groupId).collection("messages")
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
                    
                    var pollData: Poll? = nil
                    if let pollDict = data["poll"] as? [String: Any], type == .poll {
                        // Parse thủ công hoặc dùng JSONDecoder
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
                    
                    return Message(id: id, text: text, type: type, photoWidth: pWidth, photoHeight: pHeight, userId: userId, userName: userName, timestamp: timestamp, userAvatarUrl: userAvatarUrl, replyText: replyText, replyUser: replyUser,readBy: readBy, poll: pollData, reacts: reactions)
                }
            }
        subscribeToTypingStatus()
    }
    
    // Gửi poll
    func sendPoll(question: String, options: [String], allowMultiple: Bool) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        // Chuẩn bị dữ liệu Poll
        let pollOptions = options.map { PollOption(text: $0) }
        
        // Convert sang Dictionary để lưu Firestore
        let optionsData = pollOptions.map {
            ["id": $0.id, "text": $0.text, "voterIds": []]
        }
        
        let pollData: [String: Any] = [
            "question": question,
            "options": optionsData,
            "allowMultipleVotes": allowMultiple
        ]
        
        // Tạo data tin nhắn
        let data: [String: Any] = [
            "text": "Poll: \(question)", // Text hiển thị thông báo
            "type": "poll",
            "userId": currentUid,
            "userName": currentUserName,
            "userAvatarUrl": currentUserAvatarUrl,
            "timestamp": Timestamp(date: Date()),
            "poll": pollData
        ]
        
        // Gửi lên Firestore
        db.collection("groups").document(groupId).collection("messages").addDocument(data: data)
        
        // Update latest message cho Group
        db.collection("groups").document(groupId).updateData([
            "latestMessage": "Poll: \(question)",
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    // Xử lý vote poll
    func handleVote(message: Message, optionId: String) {
        guard let currentPoll = message.poll, let currentUid = Auth.auth().currentUser?.uid else { return }
        
        var newOptions = currentPoll.options
        
        // Tìm index của option được bấm
        guard let index = newOptions.firstIndex(where: { $0.id == optionId }) else { return }
        
        let isVoted = newOptions[index].voterIds.contains(currentUid)
        
        if isVoted {
            // Đã vote rồi -> Bấm lần nữa là huỷ vote
            newOptions[index].voterIds.removeAll { $0 == currentUid }
        } else {
            // Chưa vote -> Xử lý thêm vote
            
            if !currentPoll.allowMultipleVotes {
                // Nếu là Single Choice thì phải xoá vote ở các option khác trước
                for i in 0..<newOptions.count {
                    if newOptions[i].voterIds.contains(currentUid) {
                        newOptions[i].voterIds.removeAll { $0 == currentUid }
                    }
                }
            }
            // Thêm id mình vào option này
            newOptions[index].voterIds.append(currentUid)
        }
        
        // Cập nhật lại Firestore
        let updatedOptionsData = newOptions.map {
            ["id": $0.id, "text": $0.text, "voterIds": $0.voterIds]
        }
        
        // Chỉ update trường "options" bên trong field "poll"
        db.collection("groups").document(groupId).collection("messages").document(message.id).updateData([
            "poll.options": updatedOptionsData
        ])
    }
    
    // Hàm gửi Text
    func sendTextMessage(replyTo: Message? = nil) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return } //trim()
        performSendMessage(content: text, type: "text", replyTo: replyTo , lastestMessage: text)
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
    private func performSendMessage(content: String, type: String, width: CGFloat = 0, height: CGFloat = 0, replyTo: Message? = nil, lastestMessage : String) {
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
        db.collection("groups").document(self.groupId).collection("messages").addDocument(data: data)
        
        db.collection("groups").document(self.groupId).updateData([
            "latestMessage": lastestMessage,
            "updatedAt": Timestamp(date: Date()) // Cập nhật thời gian để nhảy lên đầu
        ])
        
    }
    
    // Hàm thả react
    func sendReaction(messageId: String, icon: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let fieldName = "reactions.\(currentUserID)"
        
        db.collection("groups").document(self.groupId).collection("messages").document(messageId).updateData([fieldName: icon])
        { err in
            if let err = err { print("GroupChatViewModel_3: \(err)") }
        }
    }
    
    // Hàm xoá react
    func cancelReaction(messageId: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let fieldName = "reactions.\(currentUserID)"
        
        db.collection("groups").document(self.groupId).collection("messages").document(messageId).updateData([fieldName: FieldValue.delete()])
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
        db.collection("groups").document(self.groupId).collection("messages").document(message.id).updateData([
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
        db.collection("groups").document(self.groupId).collection("messages")
            .document(message.id)
            .updateData([
                "readBy": FieldValue.arrayUnion([currentUid])
            ]) { error in
                if let error = error {
                    print("GroupChatViewModel_6: \(error.localizedDescription)")
                }
            }
    }
    deinit {
        typingListener?.remove()
    }
    
    // Chuyển admin
    func transferAdminRights(to userId: String, name: String,completion: @escaping (Bool) -> Void) {
        db.collection("groups").document(groupId).updateData([
            "adminId": userId
        ]) { error in
            if let error = error {
                print("Error transfer admin: \(error)")
                completion(false)
            } else {
                let msgContent = "Admin rights transferred to \(name)"
                self.performSendMessage(content: msgContent, type: "system", lastestMessage: msgContent)
                completion(true)
            }
        }
    }
    
    // Rời nhóm
    func leaveGroup(completion: @escaping (Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("groups").document(groupId).updateData([
            "members": FieldValue.arrayRemove([currentUid])
        ]) { error in
            if let error = error {
                print("Error leaving group: \(error)")
                completion(false)
            } else {
                self.performSendMessage(content: "\(self.currentUserName) left the group", type: "system", lastestMessage: "\(self.currentUserName) left the group.")
                completion(true)
            }
        }
    }
    
    // Xoá nhóm
    func deleteGroup(completion: @escaping (Bool) -> Void) {
        let groupRef = db.collection("groups").document(groupId)
        
        // Tạo batch để xử lý xoá hàng loạt
        let batch = db.batch()
        
        // Dùng DispatchGroup để đợi fetch xong dữ liệu từ các sub-collections
        let dispatchGroup = DispatchGroup()
        var fetchError: Error?
        
        // Lấy và xoá collection 'messages'
        dispatchGroup.enter()
        groupRef.collection("messages").getDocuments { snapshot, error in
            if let error = error { fetchError = error }
            
            // Duyệt từng tin nhắn và thêm lệnh xoá vào batch
            snapshot?.documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }
            dispatchGroup.leave()
        }
        
        // Lấy và xoá collection 'typing'
        dispatchGroup.enter()
        groupRef.collection("typing").getDocuments { snapshot, error in
            if let error = error { fetchError = error }
            
            snapshot?.documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }
            dispatchGroup.leave()
        }
        
        // Sau khi đã lấy hết dữ liệu con thì thực thi xoá
        dispatchGroup.notify(queue: .main) {
            if let error = fetchError {
                print("Error fetching sub-collections: \(error)")
                completion(false)
                return
            }
            
            // Xoá document Group chính
            batch.deleteDocument(groupRef)
            
            // Commit batch - Gửi lệnh lên server
            batch.commit { error in
                if let error = error {
                    print("Error deleting group data: \(error)")
                    completion(false)
                } else {
                    print("Group and all sub-data deleted successfully.")
                    completion(true)
                }
            }
        }
    }
}

