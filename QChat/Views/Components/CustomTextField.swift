//
//  CustomTextField.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var systemIcon: String? = nil
    var secret: Bool = false
    
    var body: some View {
        HStack {
            // Nếu có icon thì hiển thị
            if let icon = systemIcon {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
            }
            if secret {
                SecureField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
