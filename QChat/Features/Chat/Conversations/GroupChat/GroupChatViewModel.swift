//
//  GroupChatViewModel.swift
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
    
    // Typing
    @Published var typingUserNames: [String] = []
    
    // Ghim
    @Published var pinnedMessageId: String? = nil
    @Published var pinnedMessageContent: String? = nil
    
    @Published var memberIds: [String] = []
    
    @Published var nickNames: [String:String] = [:]
    
    
    // Schedule
    @Published var scheduledMessages : [ScheduledMessage] = []
    var activeTimers : [String:Timer] = [:]
    var storeKey : String {
        return "scheduled_messages_\(groupId)"
    }
    
    let groupId: String
    
    let db = Firestore.firestore()
    
    var typingListener: ListenerRegistration?
    
    // Getter lọc ảnh
    var galleryMessages: [Message] {
        return messages.filter { $0.type == .image }
    }
    
    init(groupId: String, initialMemberIds: [String] = []) {
        self.groupId = groupId
        self.memberIds = initialMemberIds
        fetchCurrentUserProfile()
        fetchMessages()
        fetchAllUsers()
        listenToGroupUpdates()
        loadScheduledMessages()
    }
    
    // Lưu list schedule vào userdefault
    func saveScheduledMessages(){
        if let encoded = try? JSONEncoder().encode(scheduledMessages){
            UserDefaults.standard.set(encoded, forKey: storeKey)
        }
    }
    
    // Load list lên khi mở app
    func loadScheduledMessages() {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let decoded = try? JSONDecoder().decode([ScheduledMessage].self, from: data) {
            
            self.scheduledMessages = decoded
            
            restoreTimers()
        }
    }
    
    // Tính lại thời gian
    func restoreTimers() {
        for item in scheduledMessages {
            // Tính toán lại thời gian còn lại
            let timeInterval = item.scheduleDate.timeIntervalSinceNow
            
            if timeInterval <= 0 {
                // Nếu đã quá hạn thì gửi luôn
                performSendMessage(content: item.content, type: "text", lastestMessage: item.content)
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
        
        db.collection("groups").document(groupId).updateData(["nickNames": updateNickNames])
    }
    
    // Hiển thị tên
    func getDisplayName (userId: String, defaultName: String) -> String {
        return nickNames[userId] ?? defaultName
    }
    
    
    
    deinit {
        typingListener?.remove()
    }
}
