//
//  GroupInfoView.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//

import SwiftUI

struct GroupInfoView: View {
    @ObservedObject var viewModel: GroupChatViewModel
    @Environment(\.dismiss) var dismiss
    
    // Trạng thái cho View
    @State private var selectedTab: Int = 0 // 0: Thành viên, 1: Ảnh, 2: Tìm kiếm
    @State private var searchText: String = ""
    
    // Xử lý xem ảnh
    @State private var showImageViewer = false
    @State private var selectedImageName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Segment Control để chuyển tab
                Picker("Options", selection: $selectedTab) {
                    Text("Member").tag(0)
                    Text("Gallery").tag(1)
                    Text("Search").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Nội dung từng Tab
                if selectedTab == 0 {
                    membersList
                } else if selectedTab == 1 {
                    mediaGallery
                } else {
                    searchMessageView
                }
            }
            .navigationTitle("Group Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            // Tích hợp ImageViewer
            .overlay(
                ZStack {
                    if showImageViewer {
                        ImageViewer(imageName: selectedImageName, isShowing: $showImageViewer)
                            .zIndex(100)
                    }
                }
            )
        }
        .onAppear {
            // Đảm bảo load danh sách user khi vào màn hình này
            if viewModel.allUsers.isEmpty {
                viewModel.fetchAllUsers()
            }
        }
    }
    
    // Tab1: Danh sách thành viên
    private var membersList: some View {
        List(viewModel.allUsers) { user in
            HStack(spacing: 12) {
                // Avatar
                AvatarView(user: user, size: 35, displayOnl: true)
                
                VStack(alignment: .leading) {
                    Text(user.username)
                        .font(.headline)
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .listStyle(.plain)
    }
    
    // Tab2: Gallery
    private var mediaGallery: some View {
        ScrollView {
            if viewModel.galleryMessages.isEmpty {
                Text("No photo")
                    .foregroundColor(.gray)
                    .padding(.top, 50)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 2)], spacing: 2) {
                    ForEach(viewModel.galleryMessages, id: \.id) { msg in
                        Button {
                            self.selectedImageName = msg.text // msg.text lưu tên ảnh
                            withAnimation {
                                self.showImageViewer = true
                            }
                        } label: {
                            // Hiển thị
                            Image(msg.text)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .contentShape(Rectangle())
                        }
                        .padding(8)
                    }
                }
            }
        }
    }
    
    // Tab 3: Tìm kiếm tin nhắn
    private var searchMessageView: some View {
        VStack {
            // SearchBar
            SearchBar(text: $searchText, placeholder: "Search message")
                .padding() 
            
            // Danh sách kết quả
            List {
                ForEach(filteredMessages, id: \.id) { msg in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            // Tên người gửi
                            Text(msg.userName)
                                .font(.caption)
                                .bold()
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            // Thời gian
                            Text(msg.timestamp, style: .date)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        // Nội dung tin nhắn (có highlight)
                        HighlightTextView(text: msg.text, target: searchText, color: .orange)
                            .font(.body)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
    }
    
    // Logic lọc tin nhắn theo từ khóa
    var filteredMessages: [Message] {
        if searchText.isEmpty {
            return [] // Không tìm gì thì không hiện
        } else {
            return viewModel.messages.filter { msg in
                // Chỉ tìm trong tin nhắn text và khớp với từ khóa (không phân biệt hoa thường)
                return msg.type == .text && msg.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
