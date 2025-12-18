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
    @State private var showAvatarSelection = false
    @State private var showLogoutAlert = false
    
    let avatarList : [String] = (1...6).map{ "avatar-\($0)"}
    
    // Cấu hình lưới 2 cột
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // Danh sách các tính năng
    let options: [ProfileOption] = [
        ProfileOption(title: "Information", iconName: "person.text.rectangle", color: .blue, type: .navigation, isDestructive: false),
        
        ProfileOption(title: "Change Password", iconName: "lock.shield", color: .purple, type: .navigation, isDestructive: false),
        
        ProfileOption(title: "Dark Mode", iconName: "moon.stars.fill", color: .orange, type: .toggle, isDestructive: false),
        
        ProfileOption(title: "Notification", iconName: "bell.badge", color: .green, type: .navigation, isDestructive: false),
        
        ProfileOption(title: "Log Out", iconName: "rectangle.portrait.and.arrow.right", color: .red, type: .button, isDestructive: true)
    ]
    
    var body: some View {
        NavigationStack (path: $path){
            ScrollView {
                VStack(spacing: 0) {
                    HeaderProfileView(user: authViewModel.currentUser) {
                        showAvatarSelection = true
                    }
                    
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
            .sheet(isPresented: $showAvatarSelection){
                ChooseAvatarView(showAvatarSelection: $showAvatarSelection, avatarList: avatarList)
                    .presentationDetents([.medium]) // Hiện 1 nửa màn
                        .presentationDragIndicator(.visible)
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Yes, log out", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    // Hàm xử lý sự kiện khi bấm vào từng ô
    func handleAction(for option: ProfileOption) {
        switch option.title {
        case "Log Out":
            showLogoutAlert = true
            
        case "Change Password":
            // Đẩy màn hình vào stack
            path.append(ProfileDestination.changePassword)
            
        case "Information":
            path.append(ProfileDestination.personalInfo)
            
        case "Notification":
            path.append(ProfileDestination.notification)
            
        default:
            print("Tính năng chưa phát triển")
        }
    }
    
    func performLogout() {
        UserStatusService.shared.updateStatus(isOnline: false)
        
        // Đợi 0.5 giây cho mạng xử lý status offline rồi mới đăng xuất
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                try authViewModel.logOut()
            } catch {
                print("ProfileView-Logout: \(error.localizedDescription)")
            }
        }
    }
    
    
}


//#Preview {
//    ProfileView()
//        .environmentObject(AuthViewModel())
//}
