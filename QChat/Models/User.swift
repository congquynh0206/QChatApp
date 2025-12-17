//
//  User.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let username: String
    var avatar: String?
    var isOnline: Bool? = nil
    var lastActive: Date? = nil
    
    // chuyển đổi sang Dictionary khi lưu lên Firebase
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "email": email,
            "username": username,
            "avatar": avatar ?? ""
        ]
        
        // Chỉ thêm vào nếu có giá trị
        if let isOnline = isOnline {
            dict["isOnline"] = isOnline
        }
        
        if let lastActive = lastActive {
            dict["lastActive"] = Timestamp(date: lastActive) // Lưu dạng Timestamp của Firebase
        }
        
        return dict
    }
}

extension User {
    init?(dictionary: [String: Any]) {
        
        guard let id = dictionary["id"] as? String,
              let email = dictionary["email"] as? String,
              let username = dictionary["username"] as? String
        else {
            return nil
        }
        
        self.id = id
        self.email = email
        self.username = username
        self.avatar = dictionary["avatar"] as? String
        
        self.isOnline = dictionary["isOnline"] as? Bool
        
        // Timestamp cần chuyển đổi sang Date
        if let timestamp = dictionary["lastActive"] as? Timestamp {
            self.lastActive = timestamp.dateValue()
        } else {
            self.lastActive = nil
        }
    }
}
