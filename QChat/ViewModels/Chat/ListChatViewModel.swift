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
    
    private let service = ChatService()
    private var firestoreListener: ListenerRegistration?
    
    init() {
        fetchRecentMessages()
    }
    
    // Hủy lắng nghe khi thoát màn hình
    deinit {
        firestoreListener?.remove()
    }
    
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
}
