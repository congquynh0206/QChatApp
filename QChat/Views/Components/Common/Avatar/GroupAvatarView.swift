//
//  GroupAvatarView.swift
//  QChat
//
//  Created by Trangptt on 17/12/25.
//

import SwiftUI

struct GroupAvatarView : View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
            Image(systemName: "person.3.fill")
                .font(.system(size: 25))
                .foregroundColor(.blue)
        }
    }
}
