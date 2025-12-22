import SwiftUI
import FirebaseAuth

struct PrivateChatView: View {
    @StateObject var viewModel: PrivateChatViewModel
    
    @Environment(\.dismiss) var dismiss
    @FocusState private var isInputFocused: Bool
    
    @State private var replyingMessage: Message? = nil
    @State private var typingTimer: Timer?
    
    init(partner: User) {
        self._viewModel = StateObject(wrappedValue: PrivateChatViewModel(partner: partner))
    }
    
    private var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            messageListView
            
            if viewModel.isPartnerTyping {
                HStack(spacing: 8) {
                    TypingIndicator()
                    AvatarView(user: viewModel.partner, size: 20, displayOnl: false)
                    Spacer()
                }
                .padding(.leading)
                .padding(.bottom, 5)
                .transition(.opacity)
            }
            
            InputMessageView(
                text: $viewModel.text,
                replyMessage: $replyingMessage,
                isFocus: $isInputFocused,
                onSend: {
                    viewModel.sendTextMessage(replyTo: replyingMessage)
                    replyingMessage = nil
                },
                onSendSticker: { stickerName in
                    viewModel.sendSticker(stickerName: stickerName)
                },
                onSendImage: { name, width, height in
                    viewModel.sendImage(name: name, width: width, height: height)
                }
            )
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: viewModel.text) { _, newValue in
            handleTyping(text: newValue)
        }
    }
}

extension PrivateChatView {
    
    private var headerView: some View {
        HStack(spacing: 15) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 40)
            }
            
            AvatarView(user: viewModel.partner, size: 35, displayOnl: true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.partner.username)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if viewModel.partner.isOnline ?? false{
                    Text("Active now")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .zIndex(1)
    }
    
    private var messageListView: some View {
        ScrollViewReader { proxy in
            if viewModel.messages.isEmpty {
                Spacer()
                Text("Send a message to start a conversation")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            messageItem(at: index, message: message)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6).opacity(0.3))
                // Cuộn khi tin nhắn thay đổi (Gửi/Nhận mới)
                .onChange(of: viewModel.messages.count) {
                    ChatUtils.scrollToBottom(proxy: proxy, messages: viewModel.messages)
                }
                // Cuộn khi bàn phím hiện lên
                .onChange(of: isInputFocused) {
                    ChatUtils.scrollToBottom(proxy: proxy, messages: viewModel.messages)
                }
                // Cuộn khi mới vào màn hình
                .onAppear {
                    ChatUtils.scrollToBottom(proxy: proxy, messages: viewModel.messages)
                }
            }
        }
    }
    
    func handleTyping(text: String) {
        if text.isEmpty {
            viewModel.sendTypingStatus(isTyping: false)
            typingTimer?.invalidate()
            return
        }
        
        viewModel.sendTypingStatus(isTyping: true)
        typingTimer?.invalidate()
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            viewModel.sendTypingStatus(isTyping: false)
        }
    }
    
    @ViewBuilder
    private func messageItem(at index: Int, message: Message) -> some View {
        VStack{

            if ChatUtils.shouldShowHeader(at: index, messages: viewModel.messages) {
                DateHeaderView(date: message.timestamp)
            }
            
            MessageRow(
                message: message,
                isMe: message.userId == currentUserId,
                isAdmin: false,
                user: viewModel.partner,
                onReply: { msg in
                    self.replyingMessage = msg
                    self.isInputFocused = true
                },
                onReaction: { msg, icon in
                    viewModel.sendReaction(messageId: msg.id, icon: icon)
                },
                cancelReaction: { msg in
                    viewModel.cancelReaction(messageId: msg.id)
                },
                onUnsend: { msg in
                    viewModel.unsendMessage(message: msg)
                },
                onAppear: { msg in
                    if msg.userId != currentUserId {
                        viewModel.markMessageAsRead(message: msg)
                    }
                }
            )
            
            // Đã xem
            if message.userId == currentUserId {
                if ChatUtils.isLastMessageByMe(message: message, messages: viewModel.messages, currentUserId: currentUserId) {
                    
                    if let readBy = message.readBy, readBy.contains(viewModel.partner.id) {
                        HStack {
                            Spacer()
                            
                            AvatarView(user: viewModel.partner, size: 15, displayOnl: false)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
    }
}
