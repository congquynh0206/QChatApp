//
//  SeenListSheet.swift
//  QChat
//
//  Created by Trangptt on 19/12/25.
//

import SwiftUI

struct SeenListSheet: View {
    let readIds: [String]
    let allUsers: [User]
    let currentUserId: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Seen by")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider()
            
            // Danh sách người đã xem
            List {
                ForEach(allUsers) { user in
                    
                    if readIds.contains(user.id) && user.id != currentUserId {
                        HStack(spacing: 12) {
                            AvatarView(user: user, size: 40, displayOnl: true)
                            
                            // Tên
                            Text(user.username)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
