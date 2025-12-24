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
    
    let isRead : Bool
    let unReadCount : Int
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            if isGroup {
                GroupAvatarView()
            }else{
                AvatarView(user: user, size: 50, displayOnl: true)
            }
            
            
            // Nội dung
            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(lastMessage)
                    .font(.subheadline)
                    .fontWeight(!isRead ? .bold : .regular)
                    .foregroundColor(isRead ? .gray : .primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Thời gian
            Text(time)
                .font(.caption)
                .foregroundColor(.gray)
            
            if !isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                
            }
        }
        .padding(.vertical, 8)
    }
}
