//
//  LoadingView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct LoadingView: View {
    var message: String = "Please wait..."
    
    var body: some View {
        ZStack {
            // Lớp nền màu đen mờ
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Hộp hiển thị Loading
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .scaleEffect(1.5)
                
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
            }
            .padding(25)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5) //
        }
    }
}



extension View {
    func showLoading(_ isLoading: Bool, message: String = "Please wait...") -> some View {
        ZStack {
            self // Nội dung gốc của màn hình
                .disabled(isLoading) // Vô hiệu hóa màn hình gốc
                .blur(radius: isLoading ? 3 : 0) // Làm mờ màn hình gốc
            
            if isLoading {
                LoadingView(message: message)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        LoadingView(message: "Logging in...")
    }
}
