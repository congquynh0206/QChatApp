//
//  InputMessageView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct InputMessageView: View {
    @Binding var text: String
    var placeholder: String = "Enter message"
    
    // Hành động khi bấm nút gửi
    var onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Ô nhập liệu
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .frame(minHeight: 40)
            
            // Nút gửi
            Button(action: {
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onSend()
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22))
                    .foregroundColor(text.isEmpty ? .gray : .blue) //
                    .padding(8)
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

