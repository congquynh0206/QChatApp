//
//  InboxRow.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct ListChatRowView: View {
    var avatarName: String
    var name: String
    var lastMessage: String
    var time: String
    var isGroup: Bool = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            ZStack {
                Circle()
                    .fill(isGroup ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(avatarName.prefix(1).uppercased())
                    .font(.title3)
                    .bold()
                    .foregroundColor(isGroup ? .blue : .gray)
            }
            
            // Nội dung
            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Thời gian
            Text(time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}
