//
//  MainTabView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI
struct MainTabView : View {
    @State var selectedTab = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    var body: some View {
        TabView(selection: $selectedTab){
            ListChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chats")
                }
                .tag(0)
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(1)
        }.accentColor(Color.blue)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            
    }
}
#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
