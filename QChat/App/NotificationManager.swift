//
//  NotificationManager.swift
//  QChat
//
//  Created by Trangptt on 24/12/25.
//


import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Xin quyền
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Xin thanh cong")
            } else if let error = error {
                print("Xin quyen that bai: \(error.localizedDescription)")
            }
        }
    }
    
    // Hẹn giờ thông báo
    func scheduleNotification(id: String, content: String, date: Date, title: String) {
        let notiContent = UNMutableNotificationContent()
        notiContent.title = title
        notiContent.body = content
        notiContent.sound = .default
        
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: notiContent, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // Hủy thông báo
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
