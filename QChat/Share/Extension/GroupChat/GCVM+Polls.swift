//
//  GCVM+.swift
//  QChat
//
//  Created by Trangptt on 22/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension GroupChatViewModel {
    
    // Gửi poll
    func sendPoll(question: String, options: [String], allowMultiple: Bool) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let pollOptions = options.map { PollOption(text: $0) }
        let optionsData = pollOptions.map { ["id": $0.id, "text": $0.text, "voterIds": []] }
        
        let pollData: [String: Any] = [
            "question": question,
            "options": optionsData,
            "allowMultipleVotes": allowMultiple
        ]
        
        let data: [String: Any] = [
            "text": "Poll: \(question)",
            "type": "poll",
            "userId": currentUid,
            "userName": currentUserName,
            "userAvatarUrl": currentUserAvatarUrl,
            "timestamp": Timestamp(date: Date()),
            "poll": pollData
        ]
        
        db.collection("groups").document(groupId).collection("messages").addDocument(data: data)
        
        db.collection("groups").document(groupId).updateData([
            "latestMessage": "Poll: \(question)",
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    // Xử lý vote
    func handleVote(message: Message, optionId: String) {
        guard let currentPoll = message.poll, let currentUid = Auth.auth().currentUser?.uid else { return }
        
        var newOptions = currentPoll.options
        guard let index = newOptions.firstIndex(where: { $0.id == optionId }) else { return }
        
        let isVoted = newOptions[index].voterIds.contains(currentUid)
        
        if isVoted {
            newOptions[index].voterIds.removeAll { $0 == currentUid }
        } else {
            if !currentPoll.allowMultipleVotes {
                for i in 0..<newOptions.count {
                    if newOptions[i].voterIds.contains(currentUid) {
                        newOptions[i].voterIds.removeAll { $0 == currentUid }
                    }
                }
            }
            newOptions[index].voterIds.append(currentUid)
        }
        
        let updatedOptionsData = newOptions.map { ["id": $0.id, "text": $0.text, "voterIds": $0.voterIds] }
        
        db.collection("groups").document(groupId).collection("messages").document(message.id).updateData([
            "poll.options": updatedOptionsData
        ])
    }
}
