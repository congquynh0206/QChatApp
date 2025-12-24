//
//  PrivateChatViewModel.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class PrivateChatViewModel: ObservableObject {
    @Published var messages = [Message]()
    @Published var text = ""
    @Published var currentUserName: String = "Unknown"
    // Schedule
    @Published var scheduledMessages : [ScheduledMessage] = []
    var activeTimers : [String:Timer] = [:]
    var storeKey : String {
        return "scheduled_messages_\(chatId)"
    }
    // Nickname
    @Published var nickNames: [String:String] = [:]
    
    // Typing
    @Published var isPartnerTyping: Bool = false
    let partner: User
    
    var typingListener: ListenerRegistration?
    
    var chatId: String {
        guard let currentUid = Auth.auth().currentUser?.uid else { return "" }
        return ChatService.getChatId(fromId: currentUid, toId: partner.id)
    }
    
    
    private var db = Firestore.firestore()
    
    init(partner: User) {
        self.partner = partner
        fetchMessage()
        fetchCurrentUserProfile()
        loadScheduledMessages()
        listenToChatOptions()
        markAsRead()
    }
    
    // Đánh dấu đã đọc rồi
    func markAsRead (){
        guard let cid = Auth.auth().currentUser?.uid else {return}
        let recentRef = db.collection("recent_messages").document(cid).collection("messages").document(partner.id)
        
        recentRef.updateData(["readBy": FieldValue.arrayUnion([cid])])
    }
    
    // Lưu vào userdefault
    func saveScheduledMessages(){
        if let encoded = try? JSONEncoder().encode(scheduledMessages){
            UserDefaults.standard.set(encoded, forKey: storeKey)
        }
    }
    
    // Load khi mở app
    func loadScheduledMessages() {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let decoded = try? JSONDecoder().decode([ScheduledMessage].self, from: data) {
            
            self.scheduledMessages = decoded
            
            restoreTimers()
        }
    }
    // tính lại thời gian
    func restoreTimers() {
        for item in scheduledMessages {
            // Tính toán lại thời gian còn lại
            let timeInterval = item.scheduleDate.timeIntervalSinceNow
            
            if timeInterval <= 0 {
                // Nếu đã quá hạn thì gửi luôn
                performSendMessage(content: item.content, type: "text")
                removeFinishedSchedule(id: item.id) // Gửi xong xoá luôn
            } else {
                // Nếu chưa quá thì chạy tiếp
                startTimer(for: item)
            }
        }
    }
    
    
    // Set biệt danh
    func setNickName (for userId: String, nickName: String){
        var updateNickNames = self.nickNames
        if nickName.isEmpty{
            updateNickNames.removeValue(forKey: userId)
        }else {
            updateNickNames[userId] = nickName
        }
        
        db.collection("chats").document(chatId).setData(["nickName": updateNickNames])
    }
    
    func listenToChatOptions() {
        guard !chatId.isEmpty else { return }
        db.collection("chats").document(chatId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                self.nickNames = data["nickName"] as? [String: String] ?? [:]
            }
        }
    }
    
    // Hiển thị tên
    func getDisplayName (userId: String, defaultName: String) -> String {
        return nickNames[userId] ?? defaultName
    }
    
    
    deinit {
        typingListener?.remove()
    }
}
