//
//  Chat.swift
//  RealChat
//
//  Created by Priya Srivastava on 02/05/25.
//

import Foundation

struct Chat: Identifiable, Codable {
    let id: UUID
    var messages: [Message]
    var lastMessage: Message? {
        messages.last
    }
    var unreadCount: Int {
        // Only count unread messages from the bot
        messages.filter { !$0.isFromUser && !$0.isRead }.count
    }
    var lastUpdated: Date {
        messages.last?.timestamp ?? Date()
    }
    var preview: String {
        lastMessage?.content ?? "No messages"
    }
    var shouldShowUnreadCount: Bool {
        // Only show unread count if the last message is from the bot
        guard let lastMessage = lastMessage else { return false }
        return !lastMessage.isFromUser && !lastMessage.isRead
    }
    
    init(id: UUID = UUID(), messages: [Message] = []) {
        self.id = id
        self.messages = messages
    }
    
    mutating func addMessage(_ message: Message) {
        messages.append(message)
    }
    
    mutating func markAllAsRead() {
        messages = messages.map { message in
            var updatedMessage = message
            updatedMessage.isRead = true
            return updatedMessage
        }
    }
    
    mutating func markAsRead() {
        for index in messages.indices {
            messages[index].isRead = true
        }
    }
}

