//
//  User.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let username: String
    var avatar: String?
    
    // chuyển đổi sang Dictionary khi lưu lên Firebase
    var dictionary: [String: Any] {
        return [
            "id": id,
            "email": email,
            "username": username,
            "avatar": avatar ?? ""
        ]
    }
}

extension User{
    init? (dictionary: [String:Any] ){
        
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
    }
}
