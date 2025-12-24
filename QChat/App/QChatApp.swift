//
//  QChatApp.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import SwiftUI
import FirebaseCore
import UserNotifications


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    struct PendingNavigation {
        let type: String
        let targetId: String
    }
    
    static var pendingNav: PendingNavigation?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String,
           let targetId = userInfo["targetId"] as? String {
            
            DispatchQueue.main.async {
                AppDelegate.pendingNav = PendingNavigation(type: type, targetId: targetId)
                NotificationCenter.default.post(name: NSNotification.Name("OpenChatFromNotification"), object: nil)
            }
        }
        completionHandler()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        completionHandler([.banner, .sound, .badge, .list])
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // Bật Firebase
        FirebaseApp.configure()
        print(" Đã kết nối Firebase thành công")
        return true
  }
}

@main
struct QChatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) var scenePhase
    
    init (){
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.userSession != nil {
                MainTabView().environmentObject(authViewModel)
            }else{
                LoginView().environmentObject(authViewModel)
            }
        }.onChange(of: scenePhase) {_, newPhase in
            switch newPhase {
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
