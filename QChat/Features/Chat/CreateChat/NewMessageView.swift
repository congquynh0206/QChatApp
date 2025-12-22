//
//  NewMessageView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct NewMessageView: View {
    @StateObject var viewModel = NewMessageViewModel()
    @State private var searchText = ""
    @State private var showCreateGroup = false
    
    @Environment(\.dismiss) var dismiss
    
    // Chọn xong trả User về
    var onSelectUser: (User) -> Void
    var onGroupCreated: ((ChatGroup) -> Void)?
    
    // Lọc danh sách
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.users
        } else {
            return viewModel.users.filter { user in
                // Tìm kiếm không phân biệt hoa thường
                user.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search by user name")
                                .padding(.horizontal)
                                .padding(.top, 10)
                
                Text("Suggest")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // List user
                LazyVStack {
                    ForEach(filteredUsers) { user in
                        Button {
                            onSelectUser(user)
                            dismiss()
                        } label: {
                            HStack(spacing: 15) {
                                // Avatar tròn
                                AvatarView(user: user, size: 50, displayOnl: true)
                                
                                Text(user.username)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline) 
            .toolbar {
                // Cancel
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                // New Group
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateGroup = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle")
                            Text("Group")
                        }
                        .font(.system(size: 14, weight: .medium))
                    }
                    
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView { newGroup in
                    // Khi tạo nhóm xong thì
                    showCreateGroup = false // Đóng sheet tạo nhóm
                    dismiss()               // Đóng luôn NewMessageView
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onGroupCreated?(newGroup)
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
    }
}

