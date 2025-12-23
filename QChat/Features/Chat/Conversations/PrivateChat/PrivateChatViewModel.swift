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
    
    
    // Typing
    @Published var isPartnerTyping: Bool = false
    let partner: User
    
    var typingListener: ListenerRegistration?
    
    var chatId: String {
        guard let currentUid = Auth.auth().currentUser?.uid else { return "" }
        return ChatService.getChatId(fromId: currentUid, toId: partner.id)
    }
    
    init(partner: User) {
        self.partner = partner
        fetchMessage()
        fetchCurrentUserProfile()
        loadScheduledMessages()
    }
    
    func saveScheduledMessages(){
        if let encoded = try? JSONEncoder().encode(scheduledMessages){
            UserDefaults.standard.set(encoded, forKey: storeKey)
        }
    }
    
    func loadScheduledMessages() {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let decoded = try? JSONDecoder().decode([ScheduledMessage].self, from: data) {
            
            self.scheduledMessages = decoded
            
            restoreTimers()
        }
    }
    
    func restoreTimers() {
        for item in scheduledMessages {
            // Tính toán lại thời gian còn lại
            let timeInterval = item.scheduleDate.timeIntervalSinceNow
            
            if timeInterval <= 0 {
                // Nếu đã quá hạn thì gửi luôn
                print("Đã quá hạn, gửi bù tin nhắn: \(item.content)")
                performSendMessage(content: item.content, type: "text")
                removeFinishedSchedule(id: item.id) // Gửi xong xoá luôn
            } else {
                // Nếu chưa quá thì chạy tiếp
                startTimer(for: item)
            }
        }
    }
    
    
    deinit {
        typingListener?.remove()
    }
}
