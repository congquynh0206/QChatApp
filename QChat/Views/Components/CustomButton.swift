//
//  CustomButton.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct CustomButton: View {
    // Các tham số có thể thay đổi
    var title: String
    var background: Color = .blue // Mặc định là màu xanh, có thể truyền màu khác
    var isValid: Bool = true      // Mặc định là nút bấm được
    var action: () -> Void        // Hành động khi bấm nút
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .bold()
                .foregroundColor(.white)
                .frame(width: 200, height: 25)
                .padding()
                .background(background)
                .cornerRadius(10)
        }
        .disabled(!isValid)
        .opacity(isValid ? 1 : 0.6)
    }
}

#Preview {
    VStack {
        // Nút trạng thái Active
        CustomButton(title: "Register", isValid: true) {
            print("Clicked")
        }
        
        // Nút trạng thái Disabled
        CustomButton(title: "Login", background: .green, isValid: false) {
            print("Clicked")
        }
    }
}
