//
//  ChatViewModel.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ChatViewModel: ObservableObject {
    // 1. Biến này chứa danh sách tin nhắn.
    // Khi biến này thay đổi (@Published), màn hình sẽ tự vẽ lại.
    @Published var messages: [Message] = []
    
    // Khởi tạo database
    private let db = Firestore.firestore()
    
    init() {
        // Tự động đăng nhập ẩn danh ngay khi mở app
        loginAnonymously()
        // Bắt đầu lắng nghe tin nhắn từ Server
        fetchMessages()
    }
    
    func loginAnonymously() {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                print("Lỗi đăng nhập: \(error.localizedDescription)")
            } else {
                print("Đã đăng nhập ẩn danh với ID: \(result?.user.uid ?? "")")
            }
        }
    }
    
    // Hàm Lấy tin nhắn (Real-time)
    func fetchMessages() {
        db.collection("messages") // Truy cập bảng 'messages'
            .order(by: "timestamp", descending: false) // Sắp xếp tin nhắn cũ trên, mới dưới
            .addSnapshotListener { querySnapshot, error in
                // Nếu có lỗi thì thoát
                if let error = error {
                    print("Lỗi lấy tin nhắn: \(error.localizedDescription)")
                    return
                }
                
                // Lấy dữ liệu về và chuyển thành mảng Message
                guard let documents = querySnapshot?.documents else { return }
                
                // Dùng map để chuyển đổi từ dữ liệu Firebase sang Model Message của ta
                self.messages = documents.compactMap { document -> Message? in
                    let data = document.data()
                    let id = document.documentID
                    let text = data["text"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    // Xử lý thời gian (Timestamp của Firebase -> Date của Swift)
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    
                    return Message(id: id, text: text, userId: userId, timestamp: timestamp)
                }
            }
    }
    
    // Hàm Gửi tin nhắn
    func sendMessage(text: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "text": text,
            "userId": currentUserID,
            "timestamp": Timestamp(date: Date()) // Lấy giờ hiện tại
        ]
        
        // Đẩy lên Firebase
        db.collection("messages").addDocument(data: data) { error in
            if let error = error {
                print("Lỗi gửi tin: \(error.localizedDescription)")
            } else {
                print("Đã gửi tin nhắn: \(text)")
            }
        }
    }
}
