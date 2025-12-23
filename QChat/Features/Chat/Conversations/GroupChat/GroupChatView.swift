//
//  ContentView.swift
//  QChat
//
//  Created by Trangptt on 11/12/25.
//

import SwiftUI
import FirebaseAuth

struct GroupChatView: View {
    let group: ChatGroup
    
    @StateObject var viewModel : GroupChatViewModel
    
    @EnvironmentObject var authModel : AuthViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isInputFocused: Bool
    
    @State private var text = ""
    @State private var replyingMessage: Message? = nil
    @State private var showGroupInfo = false
    
    // Schedule
    @State private var showSchedulePicker = false
    @State private var alertSchedule = false
    @State private var alertPastSchedule = false
    @State private var alertSuccessSchedule = false
    @State private var timeRemainSchedule : Int = 0
    @State private var showScheduledList = false
    
    // poll
    @State private var showCreatePoll = false
    
    // Typing count
    @State private var typingTimer: Timer?
    
    init(group: ChatGroup ) {
        self.group = group
        // Khởi tạo ViewModel với groupId tương ứng
        _viewModel = StateObject(wrappedValue: GroupChatViewModel(groupId: group.id, initialMemberIds: group.members))
    }
    
    private var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header View
            headerView
            
            // Message List
            messageListView
            
            // Typing
            if !viewModel.typingUserNames.isEmpty {
                HStack(spacing: 4) {
                    TypingIndicator()
                    
                    Text(typingText)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .italic()
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
            
            // Input View
            InputMessageView(
                text: $viewModel.text,
                replyMessage: $replyingMessage,
                isFocus: $isInputFocused,
                showScheduledList: $showScheduledList,
                onSend: {
                    viewModel.sendTextMessage(replyTo: replyingMessage)
                    replyingMessage = nil
                },
                onSendSticker: { stickerName in
                    viewModel.sendSticker(stickerName: stickerName)
                },
                onSendImage: { name, width, height in
                    viewModel.sendImage(name: name, width: width, height: height)
                },
                onSchedule: {
                    if viewModel.text.isEmpty {
                        alertSchedule = true
                    } else {
                        showSchedulePicker = true
                    }
                }
            )
        }
        .navigationBarBackButtonHidden(true) // Ẩn nút "< Message" mặc định
        .sheet(isPresented: $showGroupInfo) {
            GroupInfoView(group: group, viewModel: viewModel, onLeaveOrDelete: { dismiss() } )
        }
        .sheet(isPresented: $showCreatePoll) {
            CreatePollView { question, options, allowMultiple in
                viewModel.sendPoll(question: question, options: options, allowMultiple: allowMultiple)
            }
        }
        .onChange(of: viewModel.text) { _ ,newValue in
            handleTyping(text: newValue)
        }
        // Schedule list
        .sheet(isPresented: $showScheduledList) {
            ScheduledListView(messages: viewModel.scheduledMessages,
                              onDelete: viewModel.deleteScheduledMessage,
                              onUpdate: viewModel.updateScheduledMessage)
                .presentationDetents([.medium, .large])
        }
        // Schedule
        .sheet(isPresented: $showSchedulePicker) {
            SchedulePickerView { date in
                if date.timeIntervalSinceNow <= 0 {
                    alertPastSchedule = true
                }else {
                    timeRemainSchedule = Int(date.timeIntervalSinceNow)
                    alertSuccessSchedule = true
                    let content = viewModel.text
                    viewModel.scheduleTextMessage(content: content, at: date)
                    viewModel.text = ""
                }
            }
        }
        .alert ("Input is empty", isPresented: $alertSchedule){
            Button ("OK", role: .cancel){ alertSchedule = false}
            
        }message: {
            Text("Please input something before schedule")
        }
        
        .alert ("Selected in the past", isPresented: $alertPastSchedule){
            Button("OK", role: .cancel) {alertPastSchedule = false}
        } message: {
            Text("Please select time in the future")
        }
        .alert ("Success",isPresented: $alertSuccessSchedule){
            Button("OK", role: .cancel){alertSuccessSchedule = false}
        }message: {
            Text("Message will send in \(timeRemainSchedule) seconds")
        }
    }
}

extension GroupChatView {
    
    // Check xem phải admin ko
    private var isCurrentUserAdmin: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return group.adminId == uid
    }
    
    // Tách phần Header ra
    private var headerView: some View {
        HStack(spacing: 15) {
            
            // Nút back
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 40)
            }
            
            // Avatar nhóm
            GroupAvatarView()
            // Thông tin Nhóm
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Trạng thái online
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
           
            Button {
                showCreatePoll = true
            } label: {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.blue)
            }
            
            Button {
                showGroupInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 25))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(.regularMaterial)
        .zIndex(1)
    }
    
    // Tách phần danh sách tin nhắn ra riêng
    private var messageListView: some View {
        
        ScrollViewReader { proxy in
            VStack(spacing : 0){
                if let pinnedContent = viewModel.pinnedMessageContent,
                   let pinnedId = viewModel.pinnedMessageId {
                    
                    PinnedMessageBar(
                        content: pinnedContent,
                        onTap: {
                            withAnimation {
                                proxy.scrollTo(pinnedId, anchor: .center)
                            }
                        },
                        onUnpin: {
                            viewModel.unpinMessage()
                        }
                    )
                    .padding(.top, 4)
                    .zIndex(2) 
                }
                // Nếu chưa nhắn tin nào thì hiện
                if viewModel.messages.isEmpty{
                    Spacer()
                    Text("Send a message to start a conversation")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                    Spacer()
                }else{
                    ScrollView {
                        LazyVStack {
                            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                                messageItem(at: index, message: message)
                            }
                        }
                        .padding()
                    }
                
                    .background(Color(.systemGray6).opacity(0.3))
                    // Cuộn khi mới vào màn hình
                    .onAppear {
                        ChatUtils.scrollToBottom(proxy: proxy, messages: viewModel.messages)
                    }
                    .onChange(of: viewModel.messages.count) {
                        ChatUtils.scrollToBottom(proxy: proxy, messages: viewModel.messages)
                    }
                }
            }
        }
        
    }
    
    var typingText: String {
        let names = viewModel.typingUserNames
        if names.count == 1 {
            return "\(names.first!) is typing..."
        } else if names.count == 2 {
            return "\(names[0]) and \(names[1]) are typing..."
        } else {
            return "Several people are typing..."
        }
    }
    
    // Logic xử lý gửi trạng thái
    func handleTyping(text: String) {
        // Nếu ô nhập trống thì gửi false
        if text.isEmpty {
            viewModel.sendTypingStatus(isTyping: false)
            typingTimer?.invalidate()
            return
        }
        
        // Nếu đang gõ thì gửi true
        viewModel.sendTypingStatus(isTyping: true)
        
        // Hủy timer cũ (nếu có)
        typingTimer?.invalidate()
        
        // Nếu sau 2 giây không gõ gì thêm thì tự gửi false
        typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            viewModel.sendTypingStatus(isTyping: false)
        }
    }
    
    // Hàm helper để tạo User
    private func getAuthor(for message: Message) -> User {
        let displayName = viewModel.getDisplayName(userId: message.userId, defaultName: message.userName)
        return User(
            id: message.userId,
            email: "",
            username: displayName,
            avatar: message.userAvatarUrl ?? ""
        )
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
                isAdmin: isCurrentUserAdmin,
                user: getAuthor(for: message),
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
                },
                onPin: { msg in
                    viewModel.pinMessage(message: msg)
                },
                onVote: { msg, optionId in
                    viewModel.handleVote(message: msg, optionId: optionId)
                }
            )
            
            if message.userId == currentUserId  {
                if ChatUtils.isLastMessageByMe(message: message, messages: viewModel.messages, currentUserId: currentUserId){
                    HStack{
                        Spacer()
                        
                        SeenView(
                            readByIds: message.readBy,
                            allUsers: viewModel.allUsers,
                            currentUserId: currentUserId
                        )
                        .transition(.opacity)
                    }
                }
            }
        }
    }
}
