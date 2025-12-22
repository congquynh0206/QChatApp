//
//  PollMessageView.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import SwiftUI
import FirebaseAuth

struct PollMessageView: View {
    let poll: Poll
    var onVote: (String) -> Void
    
    // Tính tổng số vote
    var totalVotes: Int {
        poll.options.reduce(0) { $0 + $1.voterIds.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Câu hỏi
            Text("\(poll.question)")
                .font(.headline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Danh sách lựa chọn
            ForEach(poll.options) { option in
                Button {
                    onVote(option.id)
                } label: {
                    pollOptionRow(option: option)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Footer
            HStack {
                Text(totalVotes == 1 ? "1 vote" : "\(totalVotes) votes")
                Spacer()
                Text(poll.allowMultipleVotes ? "Multiple choice" : "Single choice")
            }
            .font(.caption2)
            .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(width: 260)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // View cho từng dòng option
    @ViewBuilder
    func pollOptionRow(option: PollOption) -> some View {
        let isMeSelected = isMeVoted(option: option)
        let percent = totalVotes > 0 ? CGFloat(option.voterIds.count) / CGFloat(totalVotes) : 0
        
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(option.text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                if option.voterIds.count > 0 {
                    Text("\(option.voterIds.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Thanh Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Nền xám
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)
                    
                    // Thanh màu xanh (phần trăm vote)
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * percent, height: 8)
                }
            }
            .frame(height: 8)
            
            // Nếu đã vote thì hiện text nhỏ bên dưới
            if isMeSelected {
                Text("You voted")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.top, 1)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isMeSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isMeSelected ? 1.5 : 1)
                .background(isMeSelected ? Color.blue.opacity(0.05) : Color.clear)
        )
    }
    
    func isMeVoted(option: PollOption) -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return option.voterIds.contains(uid)
    }
}
