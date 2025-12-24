//
//  ChatGroup.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//
import Foundation
import FirebaseFirestore

// Tin nhắn cuối cùng
struct GroupLatestMessage: Codable ,Hashable{
    var text: String
    var fromId: String
    var timestamp: Date
    var readBy: [String] //Danh sách người đã đọc
}

struct ChatGroup: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var avatarUrl: String
    var adminId: String
    var members: [String]
    
    var latestMessage: GroupLatestMessage
    
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
            "latestMessage": [
                "text": latestMessage.text,
                "fromId": latestMessage.fromId,
                "readBy": latestMessage.readBy,
                "timestamp": Timestamp(date: latestMessage.timestamp)
            ],
            "updatedAt": Timestamp(date: updatedAt),
            "nickNames": nickNames ?? [:]
        ]
    }
}

extension ChatGroup {
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
        
        // Parse dữ liệu latestMessage từ Firebase về
        if let data = dictionary["latestMessage"] as? [String: Any] {
            // Trường hợp dữ liệu mới đã là Object
            let text = data["text"] as? String ?? ""
            let fromId = data["fromId"] as? String ?? ""
            let readBy = data["readBy"] as? [String] ?? []
            let timeVal = data["timestamp"] as? Timestamp
            let timestamp = timeVal?.dateValue() ?? Date()
            
            self.latestMessage = GroupLatestMessage(text: text, fromId: fromId, timestamp: timestamp, readBy: readBy)
        } else if let textStr = dictionary["latestMessage"] as? String {
            // Trường hợp dữ liệu cũ chỉ là String thì tạo object 
            self.latestMessage = GroupLatestMessage(text: textStr, fromId: "", timestamp: Date(), readBy: [])
        } else {
            // Mặc định rỗng
            self.latestMessage = GroupLatestMessage(text: "", fromId: "", timestamp: Date(), readBy: [])
        }
        
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
