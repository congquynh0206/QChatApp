//
//  ChatService.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import Foundation
import Firebase

struct ChatService{
    static func getChatId (fromId: String, toId: String) -> String{
        return fromId < toId ? "\(fromId)_\(toId)" : "\(toId)_\(fromId)"
    }
}
