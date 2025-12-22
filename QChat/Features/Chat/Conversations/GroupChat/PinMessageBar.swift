//
//  PinMessageBar.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import SwiftUI

struct PinnedMessageBar: View {
    let content: String
    var onTap: () -> Void
    var onUnpin: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: "pin.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            // Nội dung
            VStack(alignment: .leading) {
                Text("Pinned Message")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.orange)
                
                Text(content)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            // Nút gỡ ghim
            Menu {
                Button(role: .destructive) {
                    onUnpin()
                } label: {
                    Label("Unpin", systemImage: "pin.slash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
        .padding(.horizontal)
        .onTapGesture {
            onTap() 
        }
    }
}
