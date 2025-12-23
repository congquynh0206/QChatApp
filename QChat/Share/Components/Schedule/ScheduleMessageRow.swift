//
//  ScheduleMessageRow.swift
//  QChat
//
//  Created by Trangptt on 23/12/25.
//
import SwiftUI

struct ScheduledMessageRow: View {
    let item: ScheduledMessage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text("Sends at: \(item.scheduleDate.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Image(systemName: "pencil")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
