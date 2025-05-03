//
//  ChatViewModel.swift
//  RealChat
//
//  Created by Priya Srivastava on 02/05/25.
//

import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var currentChat: Chat?
    @Published var error: String?
    @Published var isOffline = false
    @Published var showError = false
    
    private let webSocketService: WebSocketService
    private var cancellables = Set<AnyCancellable>()
    private var lastNetworkAlertTime: Date?
    private let networkAlertCooldown: TimeInterval = 30 // 30 seconds cooldown
    
    init(webSocketService: WebSocketService = WebSocketService()) {
        self.webSocketService = webSocketService
        setupSubscriptions()
        loadInitialChats()
    }

    private func setupSubscriptions() {
        webSocketService.$isNetworkAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAvailable in
                let wasOffline = self?.isOffline ?? false
                self?.isOffline = !isAvailable
                
                if !isAvailable {
                    self?.showNetworkAlertIfNeeded(message: "No internet connection")
                } else if wasOffline {
                    // When coming back online, update status of all failed messages to delivered
                    self?.updateAllFailedMessagesToDelivered()
                }
            }
            .store(in: &cancellables)
        
        webSocketService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showNetworkAlertIfNeeded(message: error)
                    
                    // Update message status to failed if there's an error
                    if let chat = self?.currentChat,
                       let index = self?.chats.firstIndex(where: { $0.id == chat.id }),
                       let lastMessage = self?.chats[index].messages.last,
                       lastMessage.isFromUser {
                        self?.updateMessageStatus(lastMessage.id, status: .failed)
                    }
                }
            }
            .store(in: &cancellables)
        
        webSocketService.$receivedMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                if let message = message {
                    self?.handleReceivedMessage(message)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialChats() {
        // Add some initial conversations
        let chat1 = Chat(messages: [
            Message(content: "Hello! How can I help you today?", isFromUser: false, status: .delivered),
            Message(content: "I have a question about your services", isFromUser: true, status: .delivered),
            Message(content: "Of course! I'd be happy to help. What would you like to know?", isFromUser: false, status: .delivered)
        ])
        
        let chat2 = Chat(messages: [
            Message(content: "Welcome to our support chat!", isFromUser: false, status: .delivered),
            Message(content: "Hi, I need help with my account", isFromUser: true, status: .delivered)
        ])
        
        chats = [chat1, chat2]
    }
    
    func connect() {
        webSocketService.connect()
    }
    
    func disconnect() {
        webSocketService.disconnect()
    }
    
    func createNewChat() -> Chat {
        let newChat = Chat(messages: [
            Message(content: "Hello! How can I assist you today?", isFromUser: false, status: .delivered)
        ])
        chats.append(newChat)
        currentChat = newChat
        return newChat
    }
    
    func selectChat(_ chat: Chat) {
        currentChat = chat
        markCurrentChatAsRead()
    }
    
    func markCurrentChatAsRead() {
        guard let chat = currentChat else { return }
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index].markAsRead()
        }
    }
    
    private func showNetworkAlertIfNeeded(message: String) {
        let now = Date()
        if let lastAlert = lastNetworkAlertTime {
            let timeSinceLastAlert = now.timeIntervalSince(lastAlert)
            if timeSinceLastAlert < networkAlertCooldown {
                return
            }
        }
        
        error = message
        showError = true
        lastNetworkAlertTime = now
    }
    
    private func updateAllFailedMessagesToDelivered() {
        for chatIndex in chats.indices {
            for messageIndex in chats[chatIndex].messages.indices {
                if chats[chatIndex].messages[messageIndex].status == .failed {
                    // First update to sent
                    chats[chatIndex].messages[messageIndex].status = .sent
                    
                    // Then update to delivered after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.chats[chatIndex].messages[messageIndex].status = .delivered
                        
                        // Update current chat if it exists
                        if let currentChat = self?.currentChat,
                           let index = self?.chats.firstIndex(where: { $0.id == currentChat.id }) {
                            self?.currentChat = self?.chats[index]
                        }
                    }
                }
            }
        }
    }
    
    func sendMessage(_ content: String) {
        guard let chat = currentChat else { return }
        
        let message = Message(content: content, isFromUser: true, status: .sending)
        
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index].messages.append(message)
            currentChat = chats[index]
            
            // Try to send the message
            if !webSocketService.send(message) {
                // If send failed (offline), update message status to failed
                updateMessageStatus(message.id, status: .failed)
                showNetworkAlertIfNeeded(message: "Message will be sent when you're back online")
            } else {
                // Update status to sent if we're online and connected
                if webSocketService.isNetworkAvailable && webSocketService.isConnected {
                    updateMessageStatus(message.id, status: .sent)
                }
            }
        }
    }
    
    private func handleReceivedMessage(_ message: Message) {
        guard let chat = currentChat else { return }
        
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            // Update status of the last user message to delivered
            if let lastUserMessageIndex = chats[index].messages.lastIndex(where: { $0.isFromUser }) {
                // First update to sent
                chats[index].messages[lastUserMessageIndex].status = .sent
                
                // Then update to delivered after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.chats[index].messages[lastUserMessageIndex].status = .delivered
                    self?.currentChat = self?.chats[index]
                }
            }
            
            // Add the received message
            chats[index].messages.append(message)
            currentChat = chats[index]
        }
    }
    
    func updateMessageStatus(_ messageId: UUID, status: MessageStatus) {
        guard let chat = currentChat,
              let chatIndex = chats.firstIndex(where: { $0.id == chat.id }),
              let messageIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == messageId }) else {
            return
        }
        
        chats[chatIndex].messages[messageIndex].status = status
        currentChat = chats[chatIndex]
    }
    
    func dismissError() {
        showError = false
        error = nil
    }
}

