//
//  PrivateChatViewEx.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//
import SwiftUI

extension PrivateChatView {
    
    // Hàm kiểm tra xem có nên hiện ngày ở vị trí index này không
    func shouldShowHeader(at index: Int, messages: [Message]) -> Bool {
        // Nếu là tin nhắn đầu tiên trong list thì luôn hiện
        if index == 0 { return true }
        
        // Lấy tin nhắn hiện tại và tin nhắn trước đó
        let currentMsg = messages[index]
        let previousMsg = messages[index - 1]
        
        // So sánh ngày
        let calendar = Calendar.current
        return !calendar.isDate(currentMsg.timestamp, inSameDayAs: previousMsg.timestamp)
    }
}
