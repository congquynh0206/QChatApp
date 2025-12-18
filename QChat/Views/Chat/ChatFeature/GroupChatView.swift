//
//  ContentView.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import SwiftUI
import FirebaseAuth

struct GroupChatView: View {
    @StateObject var viewModel = GroupChatViewModel()
    
    @EnvironmentObject var authModel : AuthViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isInputFocused: Bool
    
    @State private var text = ""
    @State private var replyingMessage: Message? = nil
    @State private var showGroupInfo = false
    
    private var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header View
            headerView
            
            // Message List
            messageListView
            
            // Input View
            InputMessageView(
                text: $viewModel.text,
                replyMessage: $replyingMessage,
                isFocus: $isInputFocused,
                onSend: {
                    viewModel.sendTextMessage(replyTo: replyingMessage)
                    replyingMessage = nil
                },
                onSendSticker: { stickerName in
                    viewModel.sendSticker(stickerName: stickerName)
                },
                onSendImage: { name, width, height in
                    viewModel.sendImage(name: name, width: width, height: height)
                }
            )
        }
        .navigationBarBackButtonHidden(true) // Ẩn nút "< Message" mặc định
        .sheet(isPresented: $showGroupInfo) {
            GroupInfoView(viewModel: viewModel)
        }
    }
}

extension GroupChatView {
    
    // Tách phần Header ra riêng
    private var headerView: some View {
        HStack(spacing: 15) {
            
            // Nút back
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 40)
            }
            
            // Avatar nhóm
            GroupAvatarView()
            // Thông tin Nhóm
            VStack(alignment: .leading, spacing: 2) {
                Text("Nhóm Chat Chung")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Trạng thái online
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button {
                showGroupInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 25))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(.regularMaterial)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
        .zIndex(1)
    }
    
    // Tách phần danh sách tin nhắn ra riêng
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        messageItem(at: index, message: message)
                    }
                }
                .padding()
            }
            // Màu nền vùng chat
            .background(Color(.systemGray6).opacity(0.3))
            .onChange(of: viewModel.messages.count) {
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // Hàm helper để tạo User
    private func getAuthor(for message: Message) -> User {
        return User(
            id: message.userId,
            email: "",
            username: message.userName,
            avatar: message.userAvatarUrl ?? ""
        )
    }
    @ViewBuilder
    private func messageItem(at index: Int, message: Message) -> some View {
        if shouldShowHeader(at: index, messages: viewModel.messages) {
            DateHeaderView(date: message.timestamp)
        }
        
        MessageRow(
            message: message,
            isMe: message.userId == currentUserId,
            user: getAuthor(for: message),
            onReply: { msg in
                self.replyingMessage = msg
                self.isInputFocused = true
            },
            onReaction: { msg, icon in
                viewModel.sendReaction(messageId: msg.id, icon: icon)
            },
            cancelReaction: { msg in
                viewModel.cancelReaction(messageId: msg.id)
            },
            onUnsend: { msg in
                viewModel.unsendMessage(message: msg)
            },
            onAppear: { msg in
                if msg.userId != currentUserId {
                    viewModel.markMessageAsRead(message: msg)
                }
            }
        )
    }
}
