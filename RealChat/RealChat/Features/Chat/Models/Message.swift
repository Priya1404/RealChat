//
//  Message.swift
//  RealChat
//
//  Created by Priya Srivastava on 02/05/25.
//

import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    let isFromUser: Bool
    var status: MessageStatus
    var isRead: Bool
    
    init(id: UUID = UUID(), 
         content: String, 
         timestamp: Date = Date(), 
         isFromUser: Bool, 
         status: MessageStatus = .sending,
         isRead: Bool = false) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFromUser = isFromUser
        self.status = status
        self.isRead = isRead
    }
}

enum MessageStatus: String, Codable {
    case sending
    case sent
    case failed
    case delivered
}

