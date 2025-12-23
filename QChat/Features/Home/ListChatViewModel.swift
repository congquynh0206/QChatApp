//
//  ListChatViewModel.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

struct RecentMessage: Identifiable, Codable {
    @DocumentID var id: String? // ID của người chat cùng
    let text: String
    let fromId: String
    let toId: String
    let timestamp: Date
    var user: User?         // thông tin người chat cùng
    
    // Tìm xem ai là người chat cùng mình
    var chatPartnerId: String {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
}

@MainActor
class ListChatViewModel: ObservableObject {
    @Published var recentMessages = [RecentMessage]()
    @Published var showNewMessageView = false
    @Published var isLoading = false
    @Published var myGroups: [ChatGroup] = []
    
    @Published var searchText = ""
    
    // Biệt danh
    @Published var partnerNicknames: [String: String] = [:]
    
    // Biến quản lý listener để tránh lắng nghe trùng lặp
    private var nicknameListeners: [String: ListenerRegistration] = [:]
    
    
    private let service = ChatService()
    private var firestoreListener: ListenerRegistration?
    
    init() {
        fetchRecentMessages()
        fetchMyGroups()
    }
    
    // Hủy lắng nghe khi thoát màn hình
    deinit {
        firestoreListener?.remove()
        nicknameListeners.values.forEach { $0.remove() }
    }
    
    // Lọc
    var filteredMessages: [RecentMessage] {
        if searchText.isEmpty {
            return recentMessages
        } else {
            return recentMessages.filter { message in
                let userName = message.user?.username ?? ""
                let displayName = getDisplayName(partner: message.user)
                return userName.localizedCaseInsensitiveContains(searchText) ||
                displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    
    // Hàm lắng nghe biệt danh
    func listenToNickname(partnerId: String) {
        // Nếu đã đang lắng nghe người này rồi thì thôi
        if nicknameListeners[partnerId] != nil { return }
        
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let chatId = ChatService.getChatId(fromId: currentUid, toId: partnerId)
        
        let listener = Firestore.firestore().collection("chats").document(chatId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data(),
                      let nicknames = data["nickName"] as? [String: String] else { return }
                
                // Lấy biệt danh của partnerId
                if let nickname = nicknames[partnerId], !nickname.isEmpty {
                    DispatchQueue.main.async {
                        self.partnerNicknames[partnerId] = nickname
                    }
                } else {
                    // Nếu không có/bị xóa thì xóa khỏi dict để hiện tên thật
                    DispatchQueue.main.async {
                        self.partnerNicknames.removeValue(forKey: partnerId)
                    }
                }
            }
        
        // Lưu listener
        nicknameListeners[partnerId] = listener
    }
    
    // Hàm lấy tên hiển thị
    func getDisplayName(partner: User?) -> String {
        guard let user = partner else { return "Unknown" }
        return partnerNicknames[user.id] ?? user.username
    }
    
    
    // Fetch các group
    func fetchMyGroups() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Lấy những nhóm chứa mình
        Firestore.firestore().collection("groups")
            .whereField("members", arrayContains: uid)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("ListChatViewModel_0: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    self.myGroups = documents.compactMap { doc -> ChatGroup? in
                        return ChatGroup(dictionary: doc.data())
                    }
                }
            }
    }
    
    // Lấy các cuộc trò chuyện gần đây
    func fetchRecentMessages() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        // Tin mới nhất lên đầu
        let query = Firestore.firestore().collection("recent_messages")
            .document(currentUid)
            .collection("messages")
            .order(by: "timestamp", descending: true)
        
        // Lắng nghe Real-time
        firestoreListener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("ListChatViewModel_1: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.isLoading = false
                return
            }
            
            // Map dữ liệu từ Firestore sang Model
            self.recentMessages = documents.compactMap { try? $0.data(as: RecentMessage.self) }
            
            //  Lấy thông tin User cho từng tin nhắn
            self.loadUserDataForMessages()
            
            self.isLoading = false
        }
    }
    
    // Điền thông tin User vào từng tin nhắn
    private func loadUserDataForMessages() {
        for index in 0..<recentMessages.count {
            let message = recentMessages[index]
            
            // Lấy ID người kia
            let partnerId = message.chatPartnerId
            
            // Gọi lên Firestore lấy thông tin User đó
            Firestore.firestore().collection("users").document(partnerId).getDocument { snapshot, error in
                if let user = try? snapshot?.data(as: User.self) {
                    // Cập nhật lại vào mảng (trên Main Thread)
                    DispatchQueue.main.async {
                        self.recentMessages[index].user = user
                    }
                }
            }
        }
    }
    
    // Xoá UI
    func deleteMessage(at offsets: IndexSet) {
        // Duyệt các index
        offsets.forEach { index in
            let messageToDelete = filteredMessages[index]
            // Xoá trên firestore
            deleteConversation(messageToDelete)
        }
    }
    
    // Xoá cuộc nói chuyện và lịch sử tin nhắn
    
    func deleteConversation(_ message: RecentMessage) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let partnerId = message.chatPartnerId
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let conversationId = ChatService.getChatId(fromId: currentUid, toId: partnerId)
        
        // Xoá trong recent để cập nhật UI
        let recentRef = db.collection("recent_messages")
            .document(currentUid)
            .collection("messages")
            .document(partnerId)
        
        batch.deleteDocument(recentRef)
        
        // Xoá lịch sử tin nhắn
        let messagesRef = db.collection("chats")
            .document(conversationId)
            .collection("messages")
        
        // Xoá từng sub-collection document bên trong
        messagesRef.getDocuments { snapshot, error in
            if let error = error {
                print("ListChatViewModel_2: \(error)")
                return
            }
            
            // Đưa tất cả lệnh xoá tin nhắn con vào batch - batch là gom nhiều lệnh vào rồi chạy 1 thể
            snapshot?.documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }
            
            // Xoá luôn cái document của đoạn chat
            let conversationRef = db.collection("chats").document(conversationId)
            batch.deleteDocument(conversationRef)
            
            // Thực thi tất cả lệnh xoá - commit batch
            batch.commit { error in
                if let error = error {
                    print("ListChatViewModel_3: \(error.localizedDescription)")
                } else {
                    // Cập nhật UI
                    DispatchQueue.main.async {
                        self.recentMessages.removeAll { $0.id == message.id }
                    }
                }
            }
        }
    }
}
