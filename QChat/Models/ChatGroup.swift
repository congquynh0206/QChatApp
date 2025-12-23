//
//  ChatGroup.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//
import Foundation
import FirebaseFirestore

struct ChatGroup: Identifiable, Codable {
    var id: String
    var name: String
    var avatarUrl: String
    var adminId: String           // Người tạo nhóm
    var members: [String]        // Danh sách ID thành viên
    var latestMessage: String
    var updatedAt: Date
    var pinnedMessageId : String?
    var pinnedMessageContent : String?
    var nickNames : [String: String]?
    
    // Convert sang Dictionary để lưu lên Firebase
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "avatarUrl": avatarUrl,
            "adminId": adminId,
            "members": members,
            "latestMessage": latestMessage,
            "updatedAt": Timestamp(date: updatedAt) 
        ]
    }
}

extension ChatGroup {
    // Init từ Dictionary khi lấy từ Firebase về
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let members = dictionary["members"] as? [String],
              let adminId = dictionary["adminId"] as? String
        else { return nil }
        
        self.id = id
        self.name = name
        self.members = members
        self.adminId = adminId
        self.avatarUrl = dictionary["avatarUrl"] as? String ?? ""
        self.latestMessage = dictionary["latestMessage"] as? String ?? ""
        
        self.pinnedMessageId = dictionary["pinnedMessageId"] as? String
        self.pinnedMessageContent = dictionary["pinnedMessageContent"] as? String
        
        if let timestamp = dictionary["updatedAt"] as? Timestamp {
            self.updatedAt = timestamp.dateValue()
        } else {
            self.updatedAt = Date()
        }
        self.nickNames = dictionary["nickNames"] as? [String:String] ?? [:]
    }
}
