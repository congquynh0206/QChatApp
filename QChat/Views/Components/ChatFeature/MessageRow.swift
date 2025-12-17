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
    @State private var showViewer = false
    var user : User?
    
    var body: some View {
        HStack() {
            if isMe { Spacer() }
            
            // Avatar chỉ hiện cho người khác (bên trái)
            if !isMe {
                AvatarView(user: user, size: 35)
            }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text(message.userName)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }
                
                switch message.type {
                case .text:
                    Text(message.text)
                        .padding(12)
                        .background(isMe ? Color.blue : Color(.systemGray5))
                        .foregroundColor(isMe ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                case .sticker:
                    Image(message.text)
                        .resizable().scaledToFit().frame(width: 100)
                    
                case .image:
                    //Hiển thị ảnh
                    Button {
                        showViewer = true
                    } label: {
                        Image(message.text)
                            .resizable()
                            .scaledToFill() // Fill đầy khung
                            .frame(
                                width: 200,
                                height: calculateHeight(maxWidth: 200)
                            )
                            .cornerRadius(16)
                            .clipped()
                    }
                }
                
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
        .fullScreenCover(isPresented: $showViewer) {
            ImageViewer(imageName: message.text, isShowing: $showViewer)
        }
    }
    // Hàm tính chiều cao
        func calculateHeight(maxWidth: CGFloat) -> CGFloat {
            guard let w = message.photoWidth, let h = message.photoHeight, w > 0 else {
                return 150 // Mặc định nếu lỗi
            }
            return (h / w) * maxWidth
        }
}
