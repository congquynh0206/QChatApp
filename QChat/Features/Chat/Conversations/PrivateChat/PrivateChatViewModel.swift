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
    }
    
    deinit {
        typingListener?.remove()
    }
}
