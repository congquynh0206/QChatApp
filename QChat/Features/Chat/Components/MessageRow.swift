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
    let isAdmin : Bool
    var user : User?
    
    @State private var showViewer = false               // Xem ảnh
    @State private var showHeartAnimation = false       // Tim bay
    @State private var showReactionList = false         //Detail react
    
    var onReply: (Message) -> Void = { _ in }
    var onReaction: (Message, String) -> Void = { _, _ in }
    var cancelReaction: (Message) -> Void = { _ in }
    var onUnsend: (Message) -> Void = { _ in }
    var onAppear: (Message) -> Void = { _ in }
    var onPin: (Message) -> Void = { _ in }
    
    var body: some View {
        HStack(alignment: .center) {
            
            if message.type == .system {
                // tin nhắn system
                HStack {
                    Spacer()
                    Text(message.text)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1)) // Nền mờ nhẹ
                        )
                    Spacer()
                }
                .padding(.bottom, 4)
                .id(message.id)
                
            } else{
                // tin nhắn bình thường
                if isMe { Spacer() }
                
                // Avatar (Trái)
                if !isMe {
                    AvatarView(user: user, size: 35, displayOnl: true)
                }
                
                VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                    // Tên người gửi
                    if !isMe {
                        Text(message.userName)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 5)
                    }
                    
                    // Hiển thị reply (Nếu có)
                    if let replyText = message.replyText, let replyUser = message.replyUser {
                        HStack {
                            Capsule()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 2)
                            
                            VStack(alignment: .leading) {
                                Text(replyUser)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                Text(replyText)
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.8))
                                    .lineLimit(1)
                            }
                        }
                        .padding(.bottom, 2)
                        // Nếu là mình thì căn phải, người khác căn trái
                        .frame(maxWidth: 200, alignment: isMe ? .trailing : .leading)
                    }
                    
                    // Nội dung tnhan
                    ZStack(alignment: .bottomTrailing) {
                        ZStack(alignment: .center) {
                            // Tin nhắn
                            messageContent
                            
                            // Hiệu ứng trái tim bay khi double tap
                            if showHeartAnimation {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 35)) // Tim to
                                    .foregroundStyle(Color.red)
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                                    .transition(.scale.combined(with: .opacity)) // Hiệu ứng phóng to + mờ dần
                            }
                        }.onTapGesture(count: 2) {
                            if message.type != .unsent{
                                // Gọi hàm thả tim
                                onReaction(message, "❤️")
                                
                                // Kích hoạt hiệu ứng
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    showHeartAnimation = true
                                }
                                
                                // Tắt hiệu ứng sau 1 giây
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation {
                                        showHeartAnimation = false
                                    }
                                }
                            }
                        }
                        
                        // Icon react
                        if let reactions = message.reacts, !reactions.isEmpty {
                            Button {
                                showReactionList = true
                            } label: {
                                reactionView(reactions: reactions)
                            }
                            .buttonStyle(PlainButtonStyle()) // Bỏ hiệu ứng nháy của button
                            .offset(x: 0, y: 10)
                        }
                        
                    }
                    
                    // Tương tác
                    .contextMenu {
                        if message.type != .unsent{
                            
                            // Thu hồi
                            if isMe  {
                                Button(role: .destructive) {
                                    onUnsend(message)
                                } label: {
                                    Label("Recall", systemImage: "trash")
                                }
                                Divider()
                            }
                            // Ghim
                            if isAdmin {
                                Button {
                                    onPin(message)
                                } label: {
                                    Label("Pin Message", systemImage: "pin")
                                }
                            }
                            
                            // Nút Reply
                            Button {
                                onReply(message)
                            } label: {
                                Label("Reply", systemImage: "arrowshape.turn.up.left")
                            }
                            
                            Divider()
                            
                            // Nút thả react
                            Button("❤️ Love") { onReaction(message, "❤️") }
                            Button("😆 Haha") { onReaction(message, "😆") }
                            Button("😮 Wow")  { onReaction(message, "😮") }
                            Button("😢 Sad")  { onReaction(message, "😢") }
                            Button("😡 Angry"){ onReaction(message, "😡") }
                            Button ("Cancel Reaction"){cancelReaction(message)}
                        }
                    }
                    // Thời gian
                    Text("\(message.timestamp.formatted(.dateTime.hour().minute()))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                        .padding(.top, (message.reacts?.isEmpty ?? true) ? 2 : 20)
                    
                }
                
                if !isMe { Spacer() }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .id(message.id)
        .fullScreenCover(isPresented: $showViewer) {
            ImageViewer(imageName: message.text, isShowing: $showViewer)
        }
        .sheet(isPresented: $showReactionList) {
            if let reacts = message.reacts {
                ReactionDetailView(reactions: reacts)
                    .presentationDetents([.fraction(0.35), .medium])
                    .presentationDragIndicator(.visible) // Hiện thanh gạch ngang để kéo xuống
            }
        }.onAppear {
            onAppear(message)
        }
    }
    
    
    // Tách nội dung tin nhắn ra cho gọn
    @ViewBuilder
    var messageContent: some View {
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
            Button {
                showViewer = true
            } label: {
                Image(message.text)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: 200,
                        height: calculateHeight(maxWidth: 200)
                    )
                    .cornerRadius(16)
                    .clipped()
            }
            
        case .unsent:
            Text("Message has been unsent")
                .font(.system(size: 14, weight: .light, design: .serif))
                .italic()
                .padding(10)
                .foregroundColor(.gray)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        case .system:
            EmptyView()
        }
        
    }
    
    // View hiển thị các icon reaction nhỏ ở góc tin nhắn
    func reactionView(reactions: [String: String]) -> some View {
        // Lấy danh sách các icon cảm xúc duy nhất, ví dụ có 2 haha thỉ chỉ hiện 1 icon haha thôi
        let uniqueReactions = Array(Set(reactions.values)).sorted().prefix(3)
        let count = reactions.count
        
        return HStack(spacing: 2) {
            ForEach(uniqueReactions, id: \.self) { icon in
                Text(icon).font(.caption2)
            }
            // Số lượng
            if count > 1 {
                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(.black)
            }
        }
        .padding(4)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(radius: 2)
    }
    
    // Hàm tính toán chiều cao ảnh
    func calculateHeight(maxWidth: CGFloat) -> CGFloat {
        guard let w = message.photoWidth, let h = message.photoHeight, w > 0 else {
            return 150
        }
        return (h / w) * maxWidth
    }
}
