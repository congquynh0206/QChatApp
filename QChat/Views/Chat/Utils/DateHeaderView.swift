//
//  DateHeaderView.swift
//  QChat
//
//  Created by Trangptt on 18/12/25.
//

import SwiftUI

struct DateHeaderView: View {
    let date: Date
    
    var body: some View {
        Text(date.chatHeaderDisplay())
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.gray)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
            .padding(.vertical, 5)
    }
}
