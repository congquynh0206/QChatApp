//
//  EditScheduleView.swift
//  QChat
//
//  Created by Trangptt on 23/12/25.
//
import SwiftUI

struct EditScheduleView: View {
    @Environment(\.dismiss) var dismiss
    let item: ScheduledMessage
    var onSave: (String, Date) -> Void
    
    @State private var content: String
    @State private var date: Date
    
    init(item: ScheduledMessage, onSave: @escaping (String, Date) -> Void) {
        self.item = item
        self.onSave = onSave
        _content = State(initialValue: item.content)
        _date = State(initialValue: item.scheduleDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Message Content") {
                    TextField("Content", text: $content)
                }
                
                Section("Reschedule Time") {
                    DatePicker("Time", selection: $date, in: Date()...)
                }
            }
            .navigationTitle("Edit Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(content, date)
                        dismiss()
                    }
                }
            }
        }
    }
}
