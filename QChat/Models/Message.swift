//
//  Message.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//
import Foundation

// Message.swift
enum MessageType: String, Codable {
    case text
    case sticker
    case image
}

struct Message: Identifiable, Codable {
    var id: String
    var text: String       
    var type: MessageType
    

    var photoWidth: CGFloat?
    var photoHeight: CGFloat?
    
    var userId: String
    var userName: String
    var timestamp: Date
    
    var userAvatarUrl: String?
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "text": text,
            "type": type.rawValue,
            "photoWidth": photoWidth ?? 0,
            "photoHeight": photoHeight ?? 0,
            "userId": userId,
            "userName": userName,
            "timestamp": timestamp,
            "userAvatarUrl": userAvatarUrl ?? ""
        ]
    }
}
