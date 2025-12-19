//
//  SearchBar.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct SearchBar: View {
    // Binding để truyền dữ liệu 2 chiều
    @Binding var text: String
    var placeholder: String = "Search..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .autocorrectionDisabled() // Tắt tự sửa lỗi chính tả
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

//#Preview {
//    SearchBar(text: .constant(""), placeholder: "Tìm kiếm...")
//}
