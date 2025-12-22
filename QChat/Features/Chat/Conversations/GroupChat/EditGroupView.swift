//
//  EditGroupView.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import SwiftUI

struct EditGroupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: EditGroupViewModel
    
    // Alert confirm xoá
    @State private var showDeleteAlert = false
    @State private var userToDelete: User?
    
    var onSaveSuccess: (() -> Void)?
    
    init(group: ChatGroup, onSaveSuccess: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: EditGroupViewModel(group: group))
        self.onSaveSuccess = onSaveSuccess
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Ô nhập tên nhóm
                TextField("Group Name", text: $viewModel.groupName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                
                //Danh sách User
                List(viewModel.allUsers) { user in
                    HStack {
                        AvatarView(user: user, size: 40, displayOnl: false)
                        
                        Text(user.username)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Hiển thị icon
                        if viewModel.currentMemberIds.contains(user.id) {
                            // User đang trong nhóm -> Hiển thị dấu trừ
                            Button {
                                userToDelete = user
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle()) // Tránh click nhầm row
                            
                        } else {
                            // User chưa trong nhóm thì hiển thị Checkbox để thêm
                            Button {
                                viewModel.toggleNewMemberSelection(userId: user.id)
                            } label: {
                                Image(systemName: viewModel.selectedNewUserIds.contains(user.id) ? "plus.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(viewModel.selectedNewUserIds.contains(user.id) ? .blue : .gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Nút Cancel bên trái
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                // Nút Save bên phải
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveChanges { success in
                            if success {
                                onSaveSuccess?() // Callback ra ngoài reload data
                                dismiss()
                            }
                        }
                    }
                    .bold()
                    .disabled(!viewModel.canSave) // Chỉ enable khi có thay đổi
                }
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Remove Member"),
                    message: Text("Are you sure you want to remove \(userToDelete?.username ?? "this user") from the group?"),
                    primaryButton: .destructive(Text("Remove")) {
                        if let user = userToDelete {
                            viewModel.removeMember(userId: user.id, userName: user.username)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .overlay {
                if viewModel.isSaving {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Saving...")
                            .padding()
                            .background(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}
