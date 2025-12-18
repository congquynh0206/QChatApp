//
//  InboxView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct ListChatView: View {
    @Binding var selectedTab : Int
    @StateObject var viewModel = ListChatViewModel()
    @EnvironmentObject var authViewModel : AuthViewModel
    
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
            List {
                Section {
                    SearchBar(text: $searchText, placeholder: "Search")
                        .padding(.bottom, 10)
                        .listRowSeparator(.hidden) // Ẩn dòng kẻ
                        .listRowInsets(EdgeInsets()) // Bỏ padding mặc định của List
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    if searchText.isEmpty {
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
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                
                Section {
                    ForEach(filteredMessages) { message in
                        ZStack {
                            NavigationLink {
                                let targetUser = message.user ?? User(
                                    id: message.chatPartnerId,
                                    email: "",
                                    username: message.user?.username ?? "Loading...",
                                    avatar: message.user?.avatar ?? nil
                                )
                                PrivateChatView(user: targetUser)
                            } label: {
                                EmptyView()
                            }
                            .opacity(0) // Ẩn link đi nhưng vẫn bấm được
                            
                            ListChatRowView(
                                avatarName: message.user?.username ?? "U",
                                name: message.user?.username ?? "Loading...",
                                lastMessage: message.text,
                                time: message.timestamp.formatted(.dateTime.hour().minute()),
                                isGroup: false,
                                user: message.user
                            )
                        }
                        .listRowSeparator(.hidden)
                        
                    }
                    .onDelete(perform: deleteMessage)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewMessage.toggle()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading){
                    Button{
                        selectedTab = 1
                    }label:{
                        AvatarView(user: authViewModel.currentUser, size: 40, displayOnl: true)
                    }
                }
            }
            .fullScreenCover(isPresented: $showNewMessage) {
                NewMessageView { user in
                    self.selectedUser = user
                    self.showChat = true
                }
            }
            .navigationDestination(isPresented: $showChat) {
                if let user = selectedUser {
                    PrivateChatView(user: user)
                }
            }
        }
    }
    func deleteMessage(at offsets: IndexSet) {
        // Duyệt các index
        offsets.forEach { index in
            // Phải dùng filteredMessages vì nếu người dùng đang Search, vị trí sẽ khác danh sách gốc
            let messageToDelete = filteredMessages[index]
            
            // Gọi ViewModel để xoá trên Server
            viewModel.deleteConversation(messageToDelete)
        }
        // viewModel.recentMessages.remove(atOffsets: offsets)
    }
}



//#Preview {
//    ListChatView(selectedTab: .constant(0))
//}
