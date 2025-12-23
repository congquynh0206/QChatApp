//
//  PrivateInfoView.swift
//  QChat
//
//  Created by Trangptt on 23/12/25.
//

import SwiftUI
import FirebaseAuth

struct PrivateInfoView: View {
    
    let partner: User
    @ObservedObject var viewModel: PrivateChatViewModel
    @Environment(\.dismiss) var dismiss
    
    // Trạng thái cho View
    @State private var selectedTab: Int = 0 // 0: Info, 1: Gallery, 2: Search
    @State private var searchText: String = ""
    
    // Xử lý xem ảnh
    @State private var showImageViewer = false
    @State private var selectedImageName = ""
    
    // Nickname
    @State private var showNicknameAlert = false
    @State private var nicknameInput: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Điều hướng Tab
                Picker("Options", selection: $selectedTab) {
                    Text("Information").tag(0)
                    Text("Gallery").tag(1)
                    Text("Search").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Nội dung từng Tab
                if selectedTab == 0 {
                    profileInfoView // Tab 1: Thông tin dọc
                    Spacer()
                } else if selectedTab == 1 {
                    mediaGallery // Tab 2: Ảnh
                } else {
                    searchMessageView // Tab 3: Tìm kiếm
                }
            }
            .navigationTitle(viewModel.getDisplayName(userId: partner.id, defaultName: partner.username))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .toolbar(showImageViewer ? .hidden : .visible, for: .navigationBar)
            // ImageViewer
            .overlay(
                ZStack {
                    if showImageViewer {
                        ImageViewer(imageName: selectedImageName, isShowing: $showImageViewer)
                            .zIndex(100)
                    }
                }
            )
            // Alert đặt biệt danh
            .alert("Set Nickname", isPresented: $showNicknameAlert) {
                TextField("Enter nickname", text: $nicknameInput)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    viewModel.setNickName(for: partner.id, nickName: nicknameInput)
                }
            } message: {
                Text("Enter a nickname for \(partner.username)")
            }
        }
    }
    
    // Information
    private var profileInfoView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Avatar
                AvatarView(user: partner, size: 100, displayOnl: true)
                    .padding(.top, 20)
                
                // Thông tin
                VStack(spacing: 8) {
                    // Tên hiển thị (To, đậm)
                    Text(viewModel.getDisplayName(userId: partner.id, defaultName: partner.username))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Nếu có biệt danh thì hiện tên thật mờ bên dưới
                    if viewModel.nickNames[partner.id] != nil {
                        Text(partner.username)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    
                    // Email
                    Text(partner.email)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Divider().padding(.horizontal)
                
                // Button đặt biệt danh
                Button {
                    // Fill biệt danh htai vào ô input
                    nicknameInput = viewModel.nickNames[partner.id] ?? ""
                    showNicknameAlert = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Set Nickname")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Gallery
    var galleryMessages: [Message] {
        return viewModel.messages.filter { $0.type == .image }
    }
    
    private var mediaGallery: some View {
        ScrollView {
            if galleryMessages.isEmpty {
                Text("No photo")
                    .foregroundColor(.gray)
                    .padding(.top, 50)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                    ForEach(galleryMessages, id: \.id) { msg in
                        Button {
                            self.selectedImageName = msg.text
                            withAnimation {
                                self.showImageViewer = true
                            }
                        } label: {
                            Image(msg.text)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 100)
                                .clipped()
                                .contentShape(Rectangle())
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    // Search
    private var searchMessageView: some View {
        VStack {
            SearchBar(text: $searchText, placeholder: "Search message")
                .padding()
            
            List {
                ForEach(filteredMessages, id: \.id) { msg in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            // Tìm kiếm : nếu là mình thì hiện "You", nếu là bạn thì hiện tên
                            let isMe = (msg.userId == Auth.auth().currentUser?.uid)
                            let senderName = isMe ? "You" : viewModel.getDisplayName(userId: partner.id, defaultName: partner.username)
                            
                            Text(senderName)
                                .font(.caption)
                                .bold()
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text(msg.timestamp, style: .date)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
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
    
    var filteredMessages: [Message] {
        if searchText.isEmpty {
            return []
        } else {
            return viewModel.messages.filter { msg in
                return msg.type == .text && msg.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
