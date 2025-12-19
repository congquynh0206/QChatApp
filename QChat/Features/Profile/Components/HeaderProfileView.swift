//
//  HeaderProfileView.swift
//  QChat
//
//  Created by Trangptt on 16/12/25.
//

import SwiftUI

struct HeaderProfileView: View {
    let user: User?
    var onAvatarClick: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Nền xanh phía sau
            Color.blue
                .frame(height: 120)
            
            VStack(spacing: 12) {
                // Avatar
                Button(action: {
                    onAvatarClick() // Gọi hành động mở bảng chọn
                }) {
                    ZStack {
                        AvatarView(user: user, size: 100, displayOnl: false)
                    
                        // Icon bên canh
                        Image(systemName: "pencil.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .gray)
                            .font(.system(size: 30))
                            .offset(x: 35, y: 35)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Tên và Email
                VStack(spacing: 4) {
                    Text(user?.username ?? "Unknown")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text(user?.email ?? "No Email")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 20)
            }
            .offset(y: 60)
        }
        .padding(.bottom, 40)
    }
}

