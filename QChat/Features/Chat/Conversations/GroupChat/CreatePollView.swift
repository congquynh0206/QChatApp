//
//  CreatePollView.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import SwiftUI

struct CreatePollView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var question = ""
    @State private var options: [String] = ["", ""] // defaut 2 option
    @State private var allowMultiple = false
    
    var onSend: (String, [String], Bool) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Question")) {
                    TextField("Ask a question...", text: $question)
                }
                
                Section(header: Text("Options")) {
                    ForEach(0..<options.count, id: \.self) { index in
                        TextField("Option \(index + 1)", text: $options[index])
                    }
                    
                    Button {
                        options.append("")
                    } label: {
                        Label("Add Option", systemImage: "plus")
                    }
                }
                
                Section {
                    Toggle("Allow Multiple Votes", isOn: $allowMultiple)
                }
            }
            .navigationTitle("New Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        // Lọc bỏ các option rỗng
                        let validOptions = options.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        
                        if !question.isEmpty && validOptions.count >= 2 {
                            onSend(question, validOptions, allowMultiple)
                            dismiss()
                        }
                    }
                    .disabled(question.isEmpty || options.filter{!$0.isEmpty}.count < 2)
                    .bold()
                }
            }
        }
    }
}
