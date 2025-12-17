//
//  AvatarView.swift
//  QChat
//
//  Created by Trangptt on 16/12/25.
//

import SwiftUI

struct AvatarView : View {
    let user : User?
    var size : CGFloat
    var body: some View {
        ZStack {
            // Kiểm tra xem user có avatar ko và ảnh đó có trong Assets không
            if let avatarName = user?.avatar, !avatarName.isEmpty, UIImage(named: avatarName) != nil {
                Image(avatarName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    
            } else {
                // Nếu chưa có, hiện chữ cái đầu
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
                    .overlay(
                        Text(user?.username.prefix(1).uppercased() ?? "U")
                            .font(.system(size: size/2.5, weight: .bold))
                            .foregroundColor(.blue)
                    )
                    .shadow(radius: 5, y: 3)
            }
        }
    }
}
