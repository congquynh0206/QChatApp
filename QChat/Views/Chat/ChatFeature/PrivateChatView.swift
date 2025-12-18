//
//  PrivateChatView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//
import SwiftUI
import FirebaseAuth

struct PrivateChatView: View {
    @StateObject var viewModel: PrivateChatViewModel
    @State private var replyingMessage: Message? = nil
    @FocusState private var isInputFocused: Bool
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: PrivateChatViewModel(user: user))
    }
    
    private var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        VStack {
            // Danh sách tin nhắn
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.messages) {message in
                            MessageRow(
                                message: message,
                                isMe: message.userId == currentUserId,
                                user: viewModel.user,
                                onReply: { msg in
                                    self.replyingMessage = msg
                                    self.isInputFocused = true
                                },
                                onReaction: { msg, icon in
                                    viewModel.sendReaction(messageId: msg.id, icon: icon)
                                },
                                cancelReaction: {msg in
                                    viewModel.cancelReaction(messageId: msg.id)
                                },
                                onUnsend: { msg in
                                        viewModel.unsendMessage(message: msg)
                                    }
                            )
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastMsg = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Thanh nhập tin nhắn
            InputMessageView(
                text: $viewModel.text,
                replyMessage: $replyingMessage,
                isFocus: $isInputFocused,
                onSend: {
                    viewModel.sendTextMessage(replyTo: replyingMessage)
                    replyingMessage = nil // Reset sau khi gửi
                },
                onSendSticker: { stickerName in
                    viewModel.sendSticker(stickerName: stickerName)
                },
                onSendImage: { name, width, height in
                    viewModel.sendImage(name: name, width: width, height: height)
                }
            )
        }
        // Tiêu đề là tên người mình đang chat
        .navigationTitle(viewModel.user.username)
        .navigationBarTitleDisplayMode(.inline)
        // Ẩn TabBar khi vào chat riêng
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.regularMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
