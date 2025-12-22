//
//  CreateGroupView.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//
import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = CreateGroupViewModel()
    
    var onComplete: ((ChatGroup) -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack {
                // Nhập tên nhóm
                TextField("Group Name", text: $viewModel.groupName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                
                // Danh sách chọn thành viên
                List(viewModel.users) { user in
                    Button {
                        viewModel.toggleSelection(user: user)
                    } label: {
                        HStack {
                            AvatarView(user: user, size: 40, displayOnl: false)
                            
                            Text(user.username)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Checkbox
                            Image(systemName: viewModel.selectedUserIds.contains(user.id) ? "plus.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundColor(viewModel.selectedUserIds.contains(user.id) ? .blue : .gray)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        // Gọi hàm createGroup mới
                        viewModel.createGroup { newGroup in
                            if let group = newGroup {
                                dismiss()
                                onComplete?(group)
                            }
                        }
                    }
                    .bold()
                    .disabled(viewModel.groupName.isEmpty || viewModel.selectedUserIds.isEmpty)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    LoadingView(message: "Creating...")
                }
            }
        }
    }
}
