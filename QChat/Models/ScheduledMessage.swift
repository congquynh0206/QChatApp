//
//  ScheduleMessage.swift
//  QChat
//
//  Created by Trangptt on 23/12/25.
//

import Foundation

struct ScheduledMessage : Identifiable, Codable{
    var id = UUID().uuidString
    var content : String
    var scheduleDate : Date
}
