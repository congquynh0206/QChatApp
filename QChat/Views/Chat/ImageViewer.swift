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
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Nền đen
            
            // Nút đóng
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation { isShowing = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle).foregroundColor(.white).padding()
                    }
                }
                Spacer()
            }
            .zIndex(10)
            
            // Hiển thị ảnh Asset
            Image(imageName)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale *= delta
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1 { withAnimation { scale = 1.0 } }
                        }
                )
        }
    }
}
