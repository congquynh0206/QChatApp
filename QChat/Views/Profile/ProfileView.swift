//
//  ProfileView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI


enum ProfileDestination: Hashable {
    case personalInfo
    case changePassword
    case notification
}

enum ProfileOptionType {
    case navigation
    case toggle
    case button     // Logout
}

struct ProfileOption: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let color: Color
    let type: ProfileOptionType
    let isDestructive: Bool
}


struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var path = NavigationPath()
    
    // Cấu hình lưới 2 cột
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // Danh sách các tính năng
    let options: [ProfileOption] = [
        ProfileOption(title: "Personal Information", iconName: "person.text.rectangle", color: .blue, type: .navigation, isDestructive: false),
        
        ProfileOption(title: "Change Password", iconName: "lock.shield", color: .purple, type: .navigation, isDestructive: false),
        
        ProfileOption(title: "Dark Mode", iconName: "moon.stars.fill", color: .orange, type: .toggle, isDestructive: false),
        
        ProfileOption(title: "Notification", iconName: "bell.badge", color: .green, type: .navigation, isDestructive: false),
        
        ProfileOption(title: "Log Out", iconName: "rectangle.portrait.and.arrow.right", color: .red, type: .button, isDestructive: true)
    ]
    
    var body: some View {
        NavigationStack (path: $path){
            ScrollView {
                VStack(spacing: 0) {
                    HeaderProfileView(user: authViewModel.currentUser)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(options) { option in
                            // Logic phân loại hiển thị
                            if option.type == .toggle {
                                // Nếu là Toggle (Dark Mode)
                                ProfileOptionCard(option: option, toggleParams: $isDarkMode)
                            } else {
                                // Nếu là Nút bấm hoặc Navigation
                                Button {
                                    handleAction(for: option)
                                } label: {
                                    ProfileOptionCard(option: option, toggleParams: .constant(false))
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: ProfileDestination.self) { destination in
                switch destination {
                case .changePassword:
                    ChangePasswordView()
                case .personalInfo:
                    PersonalInformationView()
                case .notification:
                    Text("Noti View")
                }
            }
        }
    }
    
    // Hàm xử lý sự kiện khi bấm vào từng ô
    func handleAction(for option: ProfileOption) {
        switch option.title {
        case "Log Out":
            do {
                try authViewModel.logOut()
            } catch {
                print("Lỗi logout: \(error.localizedDescription)")
            }
            
        case "Change Password":
            // Đẩy màn hình vào stack
            print("Chon change pass")
            path.append(ProfileDestination.changePassword)
            
        case "Personal Information":
            print("chon infor")
            path.append(ProfileDestination.personalInfo)
            
        case "Notification":
            path.append(ProfileDestination.notification)
            
        default:
            print("Tính năng chưa phát triển")
        }
    }
    
    
}

// View con hiển thị phần Header Avatar
struct HeaderProfileView: View {
    let user: User?
    
    var body: some View {
        ZStack(alignment: .top) {
            // Nền xanh phía sau
            Color.blue
                .frame(height: 120)
            
            VStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.white)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(user?.username.prefix(1).uppercased() ?? "U")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                    )
                    .shadow(radius: 5, y: 3)
                
                // Tên và Email
                VStack(spacing: 4) {
                    Text(user?.username ?? "Unknown")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.black)
                    
                    Text(user?.email ?? "No Email")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                .padding(.bottom, 20)
            }
            .offset(y: 60)
        }
        .padding(.bottom, 40)
    }
}

// View con hiển thị từng ô chức năng

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
        .background(Color("CardBackground"))
        .background(Color(uiColor: .secondarySystemGroupedBackground)) // Tự động đổi màu theo theme hệ thống
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
