//
//  GroupInfoView.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//

import SwiftUI
import FirebaseAuth

struct GroupInfoView: View {
    
    let group: ChatGroup
    
    @ObservedObject var viewModel: GroupChatViewModel
    @Environment(\.dismiss) var dismiss
    
    // Trạng thái cho View
    @State private var selectedTab: Int = 0 // 0: Thành viên, 1: Ảnh, 2: Tìm kiếm
    @State private var searchText: String = ""
    
    // Xử lý xem ảnh
    @State private var showImageViewer = false
    @State private var selectedImageName = ""
    
    @State private var showEditGroupSheet = false
    
    // Alert
    @State private var showLeaveAlert = false
    @State private var showDeleteAlert = false
    @State private var showTransferAdminAlert = false
    
    // Nickname
    
    @State private var showNicknameAlert = false
    @State private var nicknameInput : String = ""
    @State private var selectedUserForNickname : User?
    
    var onLeaveOrDelete: (() -> Void)?
    
    // Helper check admin
    private var isCurrentUserAdmin: Bool {
        guard let currentUid = Auth.auth().currentUser?.uid else { return false }
        return group.adminId == currentUid
    }
    
    var displayMembers: [User] {
        return viewModel.allUsers.filter { user in
            viewModel.memberIds.contains(user.id)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Điều hướng
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
                    Spacer()
                    leaveButton
                        .padding(.bottom, 20)
                } else if selectedTab == 1 {
                    mediaGallery
                } else {
                    searchMessageView
                }
            }
            // Là admin k đc rời, phải nhường admin cho ngkhac
            .alert("Cannot Leave Group", isPresented: $showTransferAdminAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You are the Admin. Please assign another member as Admin before leaving.")
            }
            
            // Confirm rời
            .alert("Leave Group", isPresented: $showLeaveAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Leave", role: .destructive) {
                    viewModel.leaveGroup { success in
                        if success {
                            dismiss()
                            onLeaveOrDelete?()
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to leave this group?")
            }
            
            // Xoá nhóm
            .alert("Delete Group", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteGroup { success in
                        if success {
                            dismiss()
                            onLeaveOrDelete?()
                        }
                    }
                }
            } message: {
                Text("You are the last member. This action will permanently delete the group.")
            }
            .navigationTitle(group.name )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isCurrentUserAdmin {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showEditGroupSheet = true
                        } label: {
                            Text("Edit")
                                .bold()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditGroupSheet) {
                EditGroupView(group: group) {
                }
            }
            .toolbar(showImageViewer ? .hidden : .visible, for: .navigationBar)
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
        List(displayMembers) { user in
            HStack(spacing: 12) {
                // Avatar
                AvatarView(user: user, size: 35, displayOnl: true)
                
                VStack(alignment: .leading) {
                    Text(viewModel.getDisplayName(userId: user.id, defaultName: user.username))
                        .font(.headline)
                    if viewModel.nickNames[user.id] != nil{
                        Text(user.username)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(user.id == group.adminId ? "Admin" : "Member")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .contextMenu {
                // Admin mới hiện
                if isCurrentUserAdmin && user.id != group.adminId {
                    Button {
                        viewModel.transferAdminRights(to: user.id, name: user.username) { success in
                        }
                    } label: {
                        Label("Promote to Admin", systemImage: "person.badge.key.fill")
                    }
                }
                
                Button {
                    selectedUserForNickname = user
                    nicknameInput = viewModel.nickNames[user.id] ?? ""
                    showNicknameAlert = true
                } label: {
                    Label("Set Nickname", systemImage: "pencil")
                }
            }
        }
        .alert("Set Nickname", isPresented: $showNicknameAlert) {
            TextField("Enter nickname", text: $nicknameInput)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let user = selectedUserForNickname {
                    viewModel.setNickName(for: user.id, nickName: nicknameInput)
                }
            }
        }
        .listStyle(.plain)
    }
    // nút rời nhóm
    private var leaveButton: some View {
        Button {
            handleLeaveAction()
        } label: {
            Text(isCurrentUserAdmin && displayMembers.count == 1 ? "Delete Group" : "Leave Group")
                .font(.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }
    
    // kiểm tra điều kiện
    private func handleLeaveAction() {
        // Là admin
        if isCurrentUserAdmin {
            // Còn hơn 1 người thì phải nhường admin
            if displayMembers.count > 1 {
                showTransferAdminAlert = true
            } else {
                // Chỉ còn 1 mình thì cho phép Xoá nhóm
                showDeleteAlert = true
            }
        } else {
            // Member thường thì cho phép rời
            showLeaveAlert = true
        }
    }
    
    // Tab2: Gallery
    private var mediaGallery: some View {
        ScrollView {
            if viewModel.galleryMessages.isEmpty {
                Text("No photo")
                    .foregroundColor(.gray)
                    .padding(.top, 50)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                    ForEach(viewModel.galleryMessages, id: \.id) { msg in
                        Button {
                            self.selectedImageName = msg.text   // lưu tên ảnh
                            withAnimation {
                                self.showImageViewer = true
                            }
                        } label: {
                            // Hiển thị
                            Image(msg.text)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 100)
                                .clipped()
                                .contentShape(Rectangle())
                        }
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
                        
                        // Nội dung tin nhắn có highlight
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
