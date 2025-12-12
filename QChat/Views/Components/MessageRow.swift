//
//  MessageRowView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//
import SwiftUI

struct MessageRow: View {
    let message: Message
    let isMe: Bool
    
    var body: some View {
        HStack() {
            if isMe { Spacer() }
            
            // Avatar chỉ hiện cho người khác (bên trái)
            if !isMe {
                Circle()
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 35, height: 35)
                    .overlay(
                        Text(message.userName.prefix(1).uppercased()) // Lấy chữ cái đầu của tên
                            .font(.caption)
                            .bold()
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text(message.userName)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }
                
                Text(message.text)
                    .padding(12)
                    .foregroundColor(isMe ? .white : .black)
                    .background(isMe ? Color.blue : Color(.systemGray5))
                // Bo góc: Nếu là mình thì nhọn góc phải dưới, người khác thì nhọn góc trái dưới
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )
                
                Text("\(message.timestamp.formatted(.dateTime.hour().minute()))")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !isMe { Spacer() }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .id(message.id)
    }
}
