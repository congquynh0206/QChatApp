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
    
    @Environment(\.dismiss) var dismiss
    
    // Chọn xong trả User về
    var onSelectUser: (User) -> Void
    
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
                                AvatarView(user: user, size: 50)
                                
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

