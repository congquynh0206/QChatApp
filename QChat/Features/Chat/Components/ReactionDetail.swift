//
//  ReactionDetailView.swift
//  QChat
//
//  Created by Trangptt on 17/12/25.
//

import SwiftUI
import FirebaseFirestore

struct ReactionDetailView: View {
    let reactions: [String: String]
    
    // Danh sách User đã thả react
    @State private var reactedUsers: [(user: User, icon: String)] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading) {
            // Tiêu đề
            HStack {
                Text("Reactions")
                    .font(.headline)
                Spacer()
                Text("\(reactions.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            
            Divider()
            
            // Danh sách người thả tim
            if reactedUsers.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(reactedUsers, id: \.user.id) { item in
                        HStack {
                            // Avatar
                            AvatarView(user: item.user, size: 40, displayOnl: true)
                            
                            // Tên
                            Text(item.user.username)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // Icon cảm xúc
                            Text(item.icon)
                                .font(.title2)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            fetchUsersInfo()
        }
    }
    
    // Hàm tải thông tin User từ danh sách ID trong reactions
    func fetchUsersInfo() {
        let userIds = Array(reactions.keys)
        guard !userIds.isEmpty else { return }
        
        let db = Firestore.firestore()
        
        var loadedUsers: [(User, String)] = []
        let group = DispatchGroup()             // Bất đồng bộ, tải đủ mới đi tiếp
        
        for uid in userIds {
            group.enter()       // Thông báo cbi chạy , tăng bộ đếm +1
            db.collection("users").document(uid).getDocument { snapshot, _ in
                defer { group.leave() }         // Báo lại là đã xong, -1
                if let data = snapshot?.data() {
                    let user = User(
                        id: uid,
                        email: "",
                        username: data["username"] as? String ?? "Unknown",
                        avatar: data["avatar"] as? String ?? ""
                    )
                    // Lấy icon tương ứng với uid này
                    if let icon = reactions[uid] {
                        loadedUsers.append((user, icon))
                    }
                }
            }
        }
        // tự chạy khi bộ đếm = 0
        group.notify(queue: .main) {    // chạy trên main
            self.reactedUsers = loadedUsers
        }
    }
}
