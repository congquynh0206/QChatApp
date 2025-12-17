//
//  ProfileOptionCard.swift
//  QChat
//
//  Created by Trangptt on 16/12/25.
//

import SwiftUI
struct ProfileOptionCard: View {
    let option: ProfileOption
    @Binding var toggleParams: Bool // Binding để điều khiển toggle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Icon
                Circle()
                    .fill(option.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: option.iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(option.color)
                    )
                
                Spacer()
                
                // Nếu là dạng Toggle thì hiện switch
                if option.type == .toggle {
                    Toggle("", isOn: $toggleParams)
                        .labelsHidden()
                        .scaleEffect(0.8) // Thu nhỏ toggle một chút cho vừa card
                }
            }
            
            Text(option.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(height: 110)
        .background(Color(uiColor: .secondarySystemGroupedBackground)) // Tự động đổi màu theo theme hệ thống
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
