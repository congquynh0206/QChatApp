//
//  QChatApp.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Bật Firebase
    FirebaseApp.configure()
    print(" Đã kết nối Firebase thành công!")
    return true
  }
}

@main
struct QChatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.userSession != nil {
                MainTabView().environmentObject(authViewModel)
            }else{
                LoginView().environmentObject(authViewModel)
            }
        }.onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                UserStatusService.shared.updateStatus(isOnline: true)
            case .inactive, .background:
                UserStatusService.shared.updateStatus(isOnline: false)
                
            @unknown default:
                break
            }
        }
    }
}
