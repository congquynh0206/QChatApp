//
//  ChatUtils.swift
//  QChat
//
//  Created by Trangptt on 19/12/25.
//

import SwiftUI

struct ChatUtils {
    
    // Logic kiểm tra hiển thị ngày
    static func shouldShowHeader(at index: Int, messages: [Message]) -> Bool {
        // Nếu là tin nhắn đầu tiên trong list thì luôn hiện
        if index == 0 { return true }
        
        // Lấy tin nhắn hiện tại và tin nhắn trước đó
        let currentMsg = messages[index]
        let previousMsg = messages[index - 1]
        
        // So sánh ngày
        let calendar = Calendar.current
        return !calendar.isDate(currentMsg.timestamp, inSameDayAs: previousMsg.timestamp)
    }
    
    // Cuộn xuống tin nhắn cuối
    static func scrollToBottom(proxy: ScrollViewProxy, messages: [Message]) {
        guard let lastMsg = messages.last else { return }

        // UI vẽ xong rồi cuộn
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                proxy.scrollTo(lastMsg.id, anchor: .bottom)
            }
        }
    }
}
