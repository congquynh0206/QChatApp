//
//  UserStatusService.swift
//  QChat
//
//  Created by Trangptt on 17/12/25.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

class UserStatusService {
    static let shared = UserStatusService()
    private let db = Firestore.firestore()
    
    // Hàm cập nhật trạng thái
    func updateStatus(isOnline: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "isOnline": isOnline,
            "lastActive": Timestamp(date: Date()) // Luôn cập nhật thời gian mới nhất
        ]
        
        db.collection("users").document(uid).updateData(data) { error in
            if let error = error {
                print("Lỗi update status: \(error.localizedDescription)")
            }
        }
    }
}
