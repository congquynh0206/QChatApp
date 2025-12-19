//
//  SeenView.swift
//  QChat
//
//  Created by Trangptt on 19/12/25.
//
import SwiftUI

struct SeenView: View {
    let readByIds: [String]?       // Danh sách ID người đã đọc
    let allUsers: [User]           // Danh sách tất cả user
    let currentUserId: String      // ID của mình
    
    @State private var showSeenList = false
    
    var body: some View {
        if let readIds = readByIds, !readIds.isEmpty {
            HStack(spacing: -5) { // Để các avatar chồng lên nhau
                ForEach(allUsers) { user in
                    // User này có trong danh sách đã đọc
                    if readIds.contains(user.id) && user.id != currentUserId {  // không phải là mình
                        AvatarView(user: user, size: 15, displayOnl: false)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    }
                }
            }
            .contentShape(Rectangle()) // Dễ bấm trúng hơn
            
            .onLongPressGesture(minimumDuration: 0.3) {
                showSeenList = true // Bật
            }
            
            // hiện sheet
            .sheet(isPresented: $showSeenList) {
                SeenListSheet(
                    readIds: readIds,
                    allUsers: allUsers,
                    currentUserId: currentUserId
                )
                // cao 30%
                .presentationDetents([.fraction(0.3), .medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
}
