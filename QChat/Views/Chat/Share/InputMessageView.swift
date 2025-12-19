//
//  InputMessageView.swift
//  QChat
//
//  Created by Trangptt on 12/12/25.
//

import SwiftUI

struct InputMessageView: View {
    @Binding var text: String
    @Binding var replyMessage: Message?
    @State var showStickerPicker = false
    @State var showImagePicker = false
    @FocusState.Binding var isFocus: Bool
    
    var placeholder: String = "Enter message"
    var onSend: () -> Void
    var onSendSticker: (String) -> Void
    var onSendImage:(String, CGFloat, CGFloat) -> Void
    
    // Danh sách Emoji
    let stickers : [String] = (1...5).map {"sticker-\($0)"}
    
    var body: some View {
        VStack(spacing: 0) {
            if let reply = replyMessage {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Replying to \(reply.userName)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text(reply.type == .text ? reply.text : "Sent a photo/sticker")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(Color.blue).frame(width: 2) // Đường kẻ xanh bên trái
                    }
                    
                    Spacer()
                    
                    // Nút hủy trả lời
                    Button {
                        withAnimation {
                            replyMessage = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            HStack(spacing: 12) {
                // Bật tắt Image
                Button(action: {
                    toggleImagePicker()
                }) {
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                        .foregroundColor(showImagePicker ? .gray : .blue)
                        .padding(8)
                }
                
                HStack(spacing: 10) {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isFocus) // Gắn focus
                        .frame(minHeight: 40)
                    // Bật tắt Sticker
                    Button {
                        toggleStickerPicker()
                    } label: {
                        Image(systemName: showStickerPicker ? "keyboard" : "face.smiling")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(.systemGray3))
                .cornerRadius(20)
                
                // Nút Gửi
                Button(action: {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 22))
                        .foregroundColor(text.isEmpty ? .gray : .blue)
                        .padding(8)
                }
                .disabled(text.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .overlay(alignment: .top) {
                Divider().background(Color(.systemGray4))
            }
            .background(.regularMaterial)
            
            // Show Sticker View
            if showStickerPicker {
                stickerPickerView
            }
            // Show Image View
            if showImagePicker {
                ImagePicker { name, width, height in
                    // Khi chọn ảnh xong -> Gửi luôn -> Ẩn picker
                    onSendImage(name, width, height)
                    showImagePicker = false
                }
            }
            
        }
        .onChange(of: isFocus) {
            if isFocus {
                withAnimation {
                    showStickerPicker = false
                    showImagePicker = false
                }
            }
        }
    }
    
    // Logic bật tắt bảng Sticker
    private func toggleStickerPicker() {
        if showStickerPicker {
            // Đang mở sticker bấm để chuyển về bàn phím
            isFocus = true
            showStickerPicker = false
        } else {
            // Đang ở bàn phím bấm để mở sticker
            isFocus = false // Ẩn bàn phím
            showImagePicker = false // Ẩn image
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showStickerPicker = true
                }
            }
        }
    }
    // Logic bật tắt ImageView
    private func toggleImagePicker() {
        if showImagePicker {
            // Đang mở image bấm để chuyển về bàn phím
            isFocus = true
            showImagePicker = false
        } else {
            // Đang ở bàn phím bấm để mở image
            isFocus = false // Ẩn bàn phím
            showStickerPicker = false // Ẩn sticker
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showImagePicker = true
                }
            }
        }
    }
    
    // Giao diện bảng Sticker
    var stickerPickerView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                ForEach(stickers, id: \.self) { stickerName in
                    Button {
                        onSendSticker(stickerName)
                    } label: {
                        Image(stickerName) // Load ảnh từ Assets
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60) // Kích thước sticker
                    }
                }
            }
            .padding()
        }
        .frame(height: 250)
        .background(Color(.systemGroupedBackground))
    }
}

