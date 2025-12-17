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
    
    var user: User? = nil
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            if isGroup {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 25))
                        .foregroundColor(.blue)
                }
            }else{
                AvatarView(user: user, size: 50)
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
