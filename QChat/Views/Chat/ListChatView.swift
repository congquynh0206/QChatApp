//
//  InboxView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct ListChatView: View {
    @StateObject var viewModel = ListChatViewModel()
    
    // Biến để quản lý điều hướng
    @State private var showNewMessage = false
    @State private var selectedUser: User? // Lưu người được chọn từ danh bạ
    @State private var showChat = false    // Kích hoạt chuyển trang
    @State var searchText = ""
    
    // Lọc theo tên
    var filteredMessages: [RecentMessage] {
        if searchText.isEmpty {
            return viewModel.recentMessages
        } else {
            return viewModel.recentMessages.filter { message in
                let userName = message.user?.username ?? ""
                return userName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search")
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                
                LazyVStack {
                    if searchText.isEmpty {
                        // Chat chung
                        NavigationLink {
                            GroupChatView()
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
                            ListChatRowView(
                                avatarName: "G",
                                name: "Nhóm Chat Chung",
                                lastMessage: "Join the chat",
                                time: "Now",
                                isGroup: true
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                        // Chat riêng
                    ForEach(filteredMessages) { message in
                        NavigationLink {
                            let targetUser = message.user ?? User(
                                id: message.chatPartnerId,
                                email: "",
                                username: message.user?.username ?? "Loading...",
                                avatar: nil
                            )
                            
                            PrivateChatView(user: targetUser)
                        } label: {
                            ListChatRowView(
                                avatarName: message.user?.username ?? "U", // Lấy tên từ User đã load
                                name: message.user?.username ?? "Loading...",
                                lastMessage: message.text,
                                time: message.timestamp.formatted(.dateTime.hour().minute()),
                                isGroup: false
                            )
                            .padding(.horizontal)
                        }
                      }
                }
                .navigationTitle("Message").font(.system(size: 30))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Button tạo tin nhắn mới
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showNewMessage.toggle()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Navigate, tạo tin nhắn mới
                .fullScreenCover(isPresented: $showNewMessage) {
                    NewMessageView { user in
                        self.selectedUser = user
                        self.showChat = true // Kích hoạt chuyển trang
                    }
                }
                
                // Chat Riêng
                .navigationDestination(isPresented: $showChat) {
                    if let user = selectedUser {
                        PrivateChatView(user: user)
                    }
                }
            }
        }
    }
}

#Preview {
    ListChatView()
}
