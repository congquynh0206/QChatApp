//
//  SchedulePickerView.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//


import SwiftUI

struct SchedulePickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
  
    var onSchedule: (Date) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Pick a time to send")
                    .font(.headline)
                    .padding(.top)
                
                // DatePicker
                DatePicker("", selection: $selectedDate, in: Date()...)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                
                Button {
                    onSchedule(selectedDate)
                    dismiss()
                } label: {
                    Text("Schedule Send")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Schedule Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(400)])
    }
}
