//
//  Poll.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import Foundation

// Một lựa chọn trong bình chọn
struct PollOption: Identifiable, Codable {
    var id: String = UUID().uuidString
    var text: String
    var voterIds: [String] = [] // Danh sách ID những người đã vote cho dòng này
}


struct Poll: Codable {
    var question: String
    var options: [PollOption]
    var allowMultipleVotes: Bool 
}
