//
//  GCVM+Scheduling.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//


import Foundation

extension GroupChatViewModel {
    
    // Hàm hẹn giờ gửi tin nhắn
    func scheduleTextMessage(content: String, at date: Date) {
        let timeInterval = date.timeIntervalSinceNow
        
        if timeInterval <= 0 {
            return
        }
        
        let newItem = ScheduledMessage(content: content, scheduleDate: date)
        self.scheduledMessages.append(newItem)
        saveScheduledMessages()
        // Gửi tbao, hiện banner
        NotificationManager.shared.scheduleNotification(
            id: newItem.id,
            type: "group",
            targetId: groupId,
            content: "Send to group \(self.groupName): \"\(newItem.content)\"",
            date: newItem.scheduleDate,
            title: "QChat - Group Message Scheduled"
        )
        
        startTimer(for: newItem)
    }
    
    // Hàm cập nhật
    func updateScheduledMessage(item: ScheduledMessage, newContent: String, newDate: Date) {
        // Tìm và cập nhật trong danh sách
        if let index = scheduledMessages.firstIndex(where: { $0.id == item.id }) {
            // Huỷ timer cũ
            cancelTimer(id: item.id)
            
            // Cập nhật data mới
            var updatedItem = scheduledMessages[index]
            updatedItem.content = newContent
            updatedItem.scheduleDate = newDate
            scheduledMessages[index] = updatedItem
            
            // Chạy timer mới
            startTimer(for: updatedItem)
            saveScheduledMessages()
        }
    }
    
    //Hàm xoá hẹn giờ
    func deleteScheduledMessage(at offsets: IndexSet) {
        offsets.forEach { index in
            let item = scheduledMessages[index]
            cancelTimer(id: item.id)
            NotificationManager.shared.cancelNotification(id: item.id)
        }
        scheduledMessages.remove(atOffsets: offsets)
        saveScheduledMessages()
    }
    
    // timer
    
    func startTimer(for item: ScheduledMessage) {
        let timeInterval = item.scheduleDate.timeIntervalSinceNow
        
        if timeInterval <= 0 { return }
        
        
        // Tạo timer
        let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Gửi tin nhắn
                self.performSendMessage(content: item.content, type: "text",lastestMessage: item.content)
                
                // Xoá khỏi danh sách chờ
                self.removeFinishedSchedule(id: item.id)
                self.saveScheduledMessages()
            }
        }
        
        // Lưu timer lại để quản lý
        activeTimers[item.id] = timer
    }
    
    // Tính lại thời gian
    func restoreTimers() {
        let currentSchedules = scheduledMessages
        for item in currentSchedules {
            // Tính toán lại thời gian còn lại
            let timeInterval = item.scheduleDate.timeIntervalSinceNow
            
            if timeInterval <= 0 {
                // Nếu đã quá hạn thì gửi luôn
                performSendMessage(content: item.content, type: "text", lastestMessage: item.content)
                removeFinishedSchedule(id: item.id) // Gửi xong xoá luôn
                saveScheduledMessages()
            } else {
                // Nếu chưa quá thì chạy tiếp
                startTimer(for: item)
            }
        }
    }
    
    private func cancelTimer(id: String) {
        if let timer = activeTimers[id] {
            timer.invalidate() // Dừng đồng hồ
            activeTimers.removeValue(forKey: id)
        }
    }
    
    // Helper xoá khi gửi xong
    func removeFinishedSchedule(id: String) {
        if let index = scheduledMessages.firstIndex(where: { $0.id == id }) {
            scheduledMessages.remove(at: index)
            activeTimers.removeValue(forKey: id) // Xoá reference timer
        }
    }
    
}
