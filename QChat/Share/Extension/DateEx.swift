//
//  DateEx.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//
import SwiftUI

extension Date {
    // Hàm format hiển thị tiêu đề ngày
    func chatHeaderDisplay() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            // Format ngày tháng năm (VD: 18/12/2025)
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: self)
        }
    }
}
