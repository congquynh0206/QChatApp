//
//  ChooseAvatarView.swift
//  QChat
//
//  Created by Trangptt on 16/12/25.
//
import SwiftUI

struct ChooseAvatarView : View {
    @Binding var showAvatarSelection :Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    var avatarList : [String]
    var body: some View {
        VStack {
            Text("Choose Avatar")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                    ForEach(avatarList, id: \.self) { iconName in
                        Button {
                            authViewModel.updateAvatar(iconName: iconName)
                            showAvatarSelection = false
                        } label: {
                            Image(iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                            // Viền xanh để biết đang chọn cái nào
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: authViewModel.currentUser?.avatar == iconName ? 3 : 0)
                                )
                        }
                    }
                }
                .padding()
            }
        }
    }
}
