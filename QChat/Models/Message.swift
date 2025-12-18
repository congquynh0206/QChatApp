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
    case unsent
}

struct Message: Identifiable, Codable {
    // Thông tin
    var id: String
    var text: String       
    var type: MessageType
    
    // Ảnh
    var photoWidth: CGFloat?
    var photoHeight: CGFloat?
    
    
    var userId: String
    var userName: String
    var timestamp: Date
    var userAvatarUrl: String?
    
    // Reply
    var replyToID : String?
    var replyText : String?
    var replyUser : String?
    
    
    var readBy: [String]?
    
    // React
    var reacts : [String:String]?
    
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
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
        if let replyID = replyToID { dict["replyToID"] = replyID }
        if let replyTxt = replyText { dict["replyText"] = replyTxt }
        if let replyUsr = replyUser { dict["replyUser"] = replyUsr }
        if let r = reacts { dict["reacts"] = r }
        
        if let readBy = readBy {
            dict["readBy"] = readBy
        }
        
        return dict
    }
}
