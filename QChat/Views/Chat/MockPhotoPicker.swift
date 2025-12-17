//
//  MockPhotoPicker.swift
//  QChat
//
//  Created by Trangptt on 16/12/25.
//
import SwiftUI

struct MockPhotoPicker: View {
    let samplePhotos : [String] = (1...5).map {"img-\($0)"}
    var onSendImage: (String, CGFloat, CGFloat) -> Void // Trả về Tên + Rộng + Cao
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(samplePhotos, id: \.self) { photoName in
                    Button {
                        // Tính kích thước thật của ảnh để lưu vào DB
                        if let uiImage = UIImage(named: photoName) {
                            onSendImage(photoName, uiImage.size.width, uiImage.size.height)
                        }
                    } label: {
                        Image(photoName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .cornerRadius(10)
                            .clipped()
                    }
                }
            }
            .padding()
        }
        .frame(height: 100)
        .background(Color(.systemGray6))
    }
}
