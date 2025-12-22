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
    // --- PROPERTIES ---
    @Published var messages: [Message] = []
    @Published var text: String = ""
    @Published var currentUserName: String = "Unknown"
    @Published var currentUserAvatarUrl: String = ""
    @Published var allUsers: [User] = []
    @Published var typingUserNames: [String] = []
    
    @Published var pinnedMessageId: String? = nil
    @Published var pinnedMessageContent: String? = nil
    
    @Published var memberIds: [String] = []
    
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
    }
    
    deinit {
        typingListener?.remove()
    }
}
