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
                        ForEach(viewModel.messages) { message in
                            MessageRow(message: message, isMe: message.userId == currentUserId)
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
            InputMessageView(text: $viewModel.text) {
                viewModel.sendMessage()
            }
        }
        // Tiêu đề là tên người mình đang chat
        .navigationTitle(viewModel.user.username)
        .navigationBarTitleDisplayMode(.inline)
        // Ẩn TabBar khi vào chat riêng
        .toolbar(.hidden, for: .tabBar)
    }
}
