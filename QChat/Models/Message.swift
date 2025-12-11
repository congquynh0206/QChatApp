//
//  Message.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//
import Foundation

struct Message: Identifiable, Codable {
    var id: String
    var text: String
    var userId: String
    var userName: String
    var timestamp: Date
}
