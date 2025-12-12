//
//  ProfileView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Header màu xanh
            ZStack(alignment: .bottom) {
                Color.blue
                    .frame(height: 120)
                    .ignoresSafeArea()
                
                // Avatar to
                Circle()
                    .fill(Color.white)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(authViewModel.currentUser?.username.prefix(1).uppercased() ?? "U")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                    )
                    .shadow(radius: 5)
                    .offset(y: 50) // Đẩy avatar xuống một nửa
            }
            .padding(.bottom, 50)
            
            // Thông tin User
            VStack(spacing: 10) {
                Text(authViewModel.currentUser?.username ?? "Unknown")
                    .font(.title2)
                    .bold()
                
                Text(authViewModel.currentUser?.email ?? "No Email")
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Nút logout
            CustomButton(title: "Log Out", background: .red, isValid: true) {
                do {
                    try authViewModel.logOut()
                } catch {
                    print("Lỗi logout: \(error.localizedDescription)")
                }
            }
            .padding(.bottom, 30)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
