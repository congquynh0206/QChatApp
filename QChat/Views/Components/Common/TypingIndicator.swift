//
//  TypingIndicator.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//

import SwiftUI

struct TypingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray) // Màu
                    .frame(width: 4, height: 4) // Kích thước
                    .offset(y: isAnimating ? -4 : 0) // Nhảy lên 4 đơn vị
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true) // Lặp lại vô hạn
                        .delay(0.2 * Double(index)), // Delay từng chấm tạo hiệu ứng sóng
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true // Kích hoạt animation khi xuất hiện
        }
    }
}
