//
//  ListChatView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI
import FirebaseAuth

struct ListChatView: View {
    @Binding var selectedTab : Int
    @ObservedObject var viewModel : ListChatViewModel
    @EnvironmentObject var authViewModel : AuthViewModel
    
    // Biến điều hướng
    @State private var showNewMessage = false
    @State private var selectedUser: User?
    @State private var showChat = false
    
    // Biến điều hướng tạo nhóm
    @State private var newlyCreatedGroup: ChatGroup?
    @State private var navigateToNewGroup = false
    
    var body: some View {
        NavigationStack {
            List {
                // Group chat
                GroupSectionView(
                    searchText: $viewModel.searchText,
                    groups: viewModel.myGroups
                )
                
                // Private Chat
                PrivateChatSectionView(viewModel: viewModel)
            }
            .listStyle(.plain)
            .navigationTitle("QChat")
            .navigationBarTitleDisplayMode(.inline)
            
            // Toolbar
            .toolbar {
                toolbarContent
            }
            // Điều hướng chat riêng
            .navigationDestination(isPresented: $showChat) {
                if let user = selectedUser {
                    PrivateChatView(partner: user)
                        .toolbar(.hidden, for: .tabBar)
                }
            }
            // Điều hướng nhóm mới
            .navigationDestination(isPresented: $navigateToNewGroup) {
                if let group = newlyCreatedGroup {
                    GroupChatView(group: group)
                        .toolbar(.hidden, for: .tabBar)
                }
            }
            // Popup tạo tin nhắn mới
            .fullScreenCover(isPresented: $showNewMessage) {
                NewMessageView(
                    onSelectUser: { user in
                        self.selectedUser = user
                        self.showChat = true
                    },
                    onGroupCreated: { group in
                        self.newlyCreatedGroup = group
                        self.showNewMessage = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.navigateToNewGroup = true
                        }
                    }
                )
            }
        }
    }
    
    // Tool bar
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading){
            Button {
                selectedTab = 1
            } label: {
                AvatarView(user: authViewModel.currentUser, size: 40, displayOnl: true)
            }
        }
        
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
}

// Group chat
struct GroupSectionView: View {
    @Binding var searchText: String
    let groups: [ChatGroup]
    
    var body: some View {
        Section {
            // Search Bar
            SearchBar(text: $searchText, placeholder: "Search")
                .padding(.bottom, 10)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
                .padding(.top, 10)
            
            // Danh sách nhóm
            ForEach(groups) { group in
                ZStack {
                    NavigationLink {
                        GroupChatView(group: group)
                            .toolbar(.hidden, for: .tabBar)
                    } label: {
                        EmptyView()
                    }.opacity(0)
                    
                    let currentUid = Auth.auth().currentUser?.uid ?? ""
                    let isRead = group.latestMessage.readBy.contains(currentUid)
                    
                    ListChatRowView(
                        avatarName: group.name,
                        name: group.name,
                        lastMessage: group.latestMessage.text,
                        time: group.updatedAt.formatted(.dateTime.hour().minute()),
                        isGroup: true,
                        isRead: isRead,
                        unReadCount: 0
                    )
                }
                .listRowSeparator(.hidden)
            }
        }
    }
}

// Private chat
struct PrivateChatSectionView: View {
    @ObservedObject var viewModel: ListChatViewModel
    
    var body: some View {
        Section {
            ForEach(viewModel.filteredMessages) { message in
                ZStack {
                    NavigationLink {
                        let targetUser = message.user ?? User(
                            id: message.chatPartnerId,
                            email: "",
                            username: viewModel.getDisplayName(partner: message.user),
                            avatar: message.user?.avatar ?? nil
                        )
                        PrivateChatView(partner: targetUser)
                    } label: {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    ListChatRowView(
                        avatarName: message.user?.username ?? "U",
                        name: viewModel.getDisplayName(partner: message.user),
                        lastMessage: message.text,
                        time: message.timestamp.formatted(.dateTime.hour().minute()),
                        isGroup: false,
                        user: message.user,
                        isRead: message.isReadByMe,
                        unReadCount: viewModel.totalUnReadCount
                    )
                    .onAppear {
                        viewModel.listenToNickname(partnerId: message.chatPartnerId)
                    }
                }
                .listRowSeparator(.hidden)
            }
            // Xoá
            .onDelete(perform: viewModel.deleteMessage)
        }
    }
}
