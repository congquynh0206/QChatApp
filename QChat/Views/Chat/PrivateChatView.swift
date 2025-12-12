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
            HStack {
                TextField("Nhập tin nhắn...", text: $viewModel.text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 40)
                
                Button {
                    viewModel.sendMessage() 
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 22))
                        .rotationEffect(.degrees(45))
                }
            }
            .padding()
        }
        // Tiêu đề là tên người mình đang chat
        .navigationTitle(viewModel.user.username)
        .navigationBarTitleDisplayMode(.inline)
        // Ẩn TabBar khi vào chat riêng
        .toolbar(.hidden, for: .tabBar)
    }
}
