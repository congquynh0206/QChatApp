//
//  ImageViewer.swift
//  QChat
//
//  Created by Trangptt on 16/12/25.
//

import SwiftUI

struct ImageViewer: View {
    let imageName: String
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Nền đen
            
            ZoomableScrollView {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            }
            .edgesIgnoringSafeArea(.all)
            
            // Nút đóng
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation { isShowing = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                            .padding(.top, 40)
                    }
                }
                Spacer()
            }
            .zIndex(10)
        }
        .transition(.opacity)
    }
}
