//
//  ContentView.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import SwiftUI
import FirebaseAuth

struct GroupChatView: View {
    @StateObject var viewModel = ChatViewModel()
    @EnvironmentObject var authModel : AuthViewModel
    
    @State private var text = ""
    
    private var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 15) {
                // Avatar nhóm
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 25))
                        .foregroundColor(.blue)
                }
                
                // Thông tin Nhóm
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nhóm Chat Chung")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Trạng thái online
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button {
                    // Hành động xem info nhóm (làm sau)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 25))
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5) // Đổ bóng
            .zIndex(1) // Đảm bảo bóng đổ đè lên tin nhắn khi cuộn
            
            
            // Danh sách tin nhắn
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.messages) { message in
                            MessageRow(message: message, isMe: message.userId == currentUserId)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            // Màu nền cho vùng chat (hơi xám nhẹ để nổi bật header trắng)
            .background(Color(.systemGray6).opacity(0.3))
            
            // Thanh nhập liệu
            HStack {
                TextField("Enter message...", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 40)
                
                Button {
                    if !text.isEmpty {
                        viewModel.sendMessage(text: text)
                        text = ""
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .padding(8)
                }
            }
            .padding()
            .background(Color(.systemGray5))
            .overlay(alignment: .top) {
                Divider()
            }
        }
    }
}

struct GroupChatView_Previews: PreviewProvider {
    static var previews: some View {
        GroupChatView().environmentObject(AuthViewModel())
    }
}
