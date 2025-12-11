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
    @Published var messages: [Message] = []
    
    @Published var currentUserName: String = "Unknown"
    
    // Khởi tạo database
    private let db = Firestore.firestore()
    
    init() {
        fetchCurrentUserProfile()
        fetchMessages()
    }
    
    func fetchCurrentUserProfile() {
            // Lấy ID người dùng đang đăng nhập
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            // Tìm trong bảng 'users' xem ông này tên là gì
            db.collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    print("Lỗi lấy user profile: \(error.localizedDescription)")
                    return
                }
                
                // Lấy dữ liệu về
                if let data = snapshot?.data(),
                   let name = data["username"] as? String {
                    // Lưu vào biến để tí nữa dùng gửi tin nhắn
                    DispatchQueue.main.async {
                        self.currentUserName = name
                    }
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
                    let userName =  data["userName"] as? String ?? "Người lạ"
                    let userId = data["userId"] as? String ?? ""
                    // Xử lý thời gian (Timestamp của Firebase -> Date của Swift)
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    
                    return Message(id: id, text: text, userId: userId,userName: userName ,timestamp: timestamp)
                }
            }
    }
    
    // Hàm Gửi tin nhắn
    func sendMessage(text: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "text": text,
            "userId": currentUserID,
            "userName": self.currentUserName,
            "timestamp": Timestamp(date: Date())
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
