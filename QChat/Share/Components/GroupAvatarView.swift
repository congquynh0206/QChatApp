//
//  GroupAvatarView.swift
//  QChat
//
//  Created by Trangptt on 17/12/25.
//

import SwiftUI

struct GroupAvatarView : View {
    var body: some View {
        Image("group-avatar")
            .resizable()
            .scaledToFill()
            .frame(width: 50, height: 50)
            .clipShape(Circle())
    }
}
