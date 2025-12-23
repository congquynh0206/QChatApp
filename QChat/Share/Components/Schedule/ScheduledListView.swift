//
//  ScheduledListView.swift
//  QChat
//
//  Created by Trangptt on 23/12/25.
//

import SwiftUI

struct ScheduledListView: View {
    
    // Danh sách tin nhắn
    let messages: [ScheduledMessage]
    
    // Các hành động (Callback)
    let onDelete: (IndexSet) -> Void
    let onUpdate: (ScheduledMessage, String, Date) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var editingItem: ScheduledMessage?
    
    var body: some View {
        NavigationView {
            ZStack {
                if messages.isEmpty {
                    emptyView
                } else {
                    messageList
                }
            }
            .navigationTitle("Scheduled Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            // Sheet sửa tin nhắn
            .sheet(item: $editingItem) { item in
                EditScheduleView(item: item) { newContent, newDate in
                    onUpdate(item, newContent, newDate)
                }
            }
        }
    }
    
    // View hiển thị khi danh sách trống
    private var emptyView: some View {
        VStack {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom, 10)
            
            Text("No scheduled messages")
                .foregroundColor(.gray)
                .font(.headline)
        }
    }
    
    // View danh sách chính
    private var messageList: some View {
        List {
            ForEach(messages) { item in
                Button {
                    editingItem = item
                } label: {
                    ScheduledMessageRow(item: item)
                }
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(.plain)
    }
}
