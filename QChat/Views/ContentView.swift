//
//  ContentView.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject var viewModel = ChatViewModel()
    // Biến lưu nội dung đang gõ
    @State private var text = ""
    
    // Lấy ID người dùng hiện tại để phân biệt tin nhắn của mình hay của người khác
    private var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        VStack {
            Text("Nhóm Chat Chung")
                .font(.title3)
                .bold()
                .padding()
            
            // Dsach tin nhắn
            ScrollViewReader { proxy in // Proxy giúp điều khiển việc cuộn
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.messages) { message in
                            MessageRow(message: message, isMe: message.userId == currentUserId)
                        }
                    }
                    .padding()
                }
                // Tự động cuộn xuống dưới cùng khi có tin nhắn mới
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            //Thanh nhập
            HStack {
                TextField("Nhập tin nhắn...", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30)
                
                Button {
                    // Logic gửi tin nhắn
                    if !text.isEmpty {
                        viewModel.sendMessage(text: text)
                        text = ""
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6)) // Màu nền xám nhẹ cho thanh nhập
        }
    }
}


// Giao diện của 1 dòng tin nhăn
struct MessageRow: View {
    let message: Message
    let isMe: Bool
    
    var body: some View {
        HStack {
            if isMe { Spacer() } // Nếu là tôi: Đẩy sang phải
            
            VStack(alignment: isMe ? .trailing : .leading) {
                
                // Nếu không phải mình thì hiện tên
                if !isMe{
                    Text("\(message.userName)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Text(message.text)
                    .padding(10)
                    .foregroundColor(isMe ? .white : .black)
                    .background(isMe ? Color.blue : Color(.systemGray5))
                    .cornerRadius(10)
                
                // Hiển thị giờ
                Text("\(message.timestamp.formatted(.dateTime.hour().minute()))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isMe { Spacer() } // Nếu là mình thì Đẩy sang trái
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .id(message.id) // Gắn ID để ScrollViewReader biết đường mà cuộn tới
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
