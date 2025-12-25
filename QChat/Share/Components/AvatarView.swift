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
    var displayOnl : Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            // avatar: nếu có ảnh thì hiện ko có thì hiện hình tròn + chữ đầu
            if let avatarName = user?.avatar, !avatarName.isEmpty, UIImage(named: avatarName) != nil {
                Image(avatarName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
                    .overlay(
                        Text(user?.username.prefix(1).uppercased() ?? "U")
                            .font(.system(size: size/2.5, weight: .bold))
                            .foregroundColor(.blue)
                    )
                    .shadow(radius: 2)
            }
            
            // trạng thái online
            if let user = user {
                // onl
                if user.isOnline == true && displayOnl{
                    Circle()
                        .fill(Color.green)
                        .frame(width: size * 0.3, height: size * 0.3)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 2, y: 2)
                    
                } else {
                   // off
                    // Chỉ hiện khi avatar > 45
                    if size > 45 && displayOnl , let lastActive = user.lastActive {
                        Text(lastActive.timeAgoDisplay())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.gray)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                            .offset(x: 5, y: 0) 
                    }
                }
            }
        }
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        
        if secondsAgo < minute {
            return "1m"
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute)m"
        } else if secondsAgo < day {
            return "\(secondsAgo / hour)h"
        } else {
            return "\(secondsAgo / day)d"
        }
    }
}
