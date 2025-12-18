//
//  HighlightTextView.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//
import SwiftUI

struct HighlightTextView: View {
    let text: String
    let target: String
    let color: Color
    
    var body: some View {
        if target.isEmpty {
            return Text(text)
        } else {
            // Tìm range của từ khoá
            if let range = text.range(of: target, options: .caseInsensitive) {
                let prefix = text[..<range.lowerBound]
                let match = text[range]
                let suffix = text[range.upperBound...]
                
                // Ghép 3 phần lại
                return Text(prefix) + Text(match).foregroundColor(color).bold() + Text(suffix)
            } else {
                return Text(text)
            }
        }
    }
}
