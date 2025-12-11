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
    
    // Hàm tiện ích để chuyển đổi sang Dictionary khi lưu lên Firebase
    var dictionary: [String: Any] {
        return [
            "id": id,
            "email": email,
            "username": username,
            "avatar": avatar ?? ""
        ]
    }
}
