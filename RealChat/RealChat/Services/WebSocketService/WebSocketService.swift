//
//  WebSocketService.swift
//  RealChat
//
//  Created by Priya Srivastava on 02/05/25.
//

import Foundation
import Combine
import Network

class WebSocketService: ObservableObject {
    private var webSocket: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "wss://demo.piesocket.com/v3/channel_1?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV"
    private var isConnecting = false
    private var reconnectTimer: Timer?
    private var messageQueue: [Message] = []
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "WebSocketService")
    
    @Published var isConnected = false
    @Published var receivedMessage: Message?
    @Published var error: String?
    @Published var isNetworkAvailable = true
    
    init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            DispatchQueue.main.async {
                let wasOffline = !self.isNetworkAvailable
                self.isNetworkAvailable = path.status == .satisfied
                
                if wasOffline && path.status == .satisfied {
                    self.connect()
                    self.processMessageQueue()
                } else if !(path.status == .satisfied) {
                    self.isConnected = false
                    self.error = "No internet connection"
                }
            }
        }
        networkMonitor.start(queue: queue)
    }
    
    func connect() {
        guard !isConnecting else { return }
        isConnecting = true
        
        guard isNetworkAvailable else {
            error = "No internet connection"
            isConnecting = false
            return
        }
        
        guard let url = URL(string: baseURL) else {
            error = "Invalid WebSocket URL"
            isConnecting = false
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        startPingTimer()
        receiveMessage()
        
        isConnected = true
        isConnecting = false
        processMessageQueue()
    }
    
    func disconnect() {
        stopPingTimer()
        webSocket?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
        isConnecting = false
    }
    
    private func startPingTimer() {
        stopPingTimer()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func sendPing() {
        guard isConnected && isNetworkAvailable else {
            reconnect()
            return
        }
        
        webSocket?.sendPing { [weak self] error in
            if let error = error {
                print("Ping failed: \(error)")
                self?.reconnect()
            }
        }
    }
    
    private func reconnect() {
        guard !isConnecting && isNetworkAvailable else { return }
        isConnecting = true
        
        disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.connect()
        }
    }
    
    func send(_ message: Message) -> Bool {
        // If offline, queue the message and return false
        guard isNetworkAvailable else {
            messageQueue.append(message)
            error = "No internet connection. Message queued."
            return false
        }
        
        // If not connected, queue the message and try to connect
        guard isConnected else {
            messageQueue.append(message)
            connect()
            return false
        }
        
        // Try to send the message
        guard let data = try? JSONEncoder().encode(message) else {
            error = "Failed to encode message"
            return false
        }
        
        let webSocketMessage = URLSessionWebSocketTask.Message.data(data)
        webSocket?.send(webSocketMessage) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.error = "Error sending message: \(error.localizedDescription)"
                    self?.isConnected = false
                    self?.messageQueue.append(message)
                    self?.reconnect()
                }
            } else {
                // Only generate bot response if we're online and connected
                if self?.isNetworkAvailable == true && self?.isConnected == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        let botResponse = Message(
                            content: self?.generateBotResponse(to: message.content) ?? "I'm sorry, I didn't understand that.",
                            isFromUser: false,
                            status: .delivered
                        )
                        self?.receivedMessage = botResponse
                    }
                }
            }
        }
        
        return isNetworkAvailable && isConnected
    }
    
    private func processMessageQueue() {
        guard isConnected && isNetworkAvailable else { return }
        
        let messagesToProcess = messageQueue
        messageQueue.removeAll()
        
        for message in messagesToProcess {
            if !send(message) {
                messageQueue.append(message)
            }
        }
    }
    
    private func generateBotResponse(to message: String) -> String {
        let lowercasedMessage = message.lowercased()
        
        if lowercasedMessage.contains("hello") || lowercasedMessage.contains("hi") {
            return "Hello! How can I help you today?"
        } else if lowercasedMessage.contains("help") {
            return "I'm here to help! What would you like to know?"
        } else if lowercasedMessage.contains("bye") || lowercasedMessage.contains("goodbye") {
            return "Goodbye! Have a great day!"
        } else if lowercasedMessage.contains("thank") {
            return "You're welcome! Is there anything else I can help you with?"
        } else if lowercasedMessage.contains("name") {
            return "I'm ChatBot, your friendly assistant!"
        } else if lowercasedMessage.contains("weather") {
            return "I'm sorry, I don't have access to weather information at the moment."
        } else if lowercasedMessage.contains("time") {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "The current time is \(formatter.string(from: Date()))"
        } else {
            return "I understand you're saying: '\(message)'. How can I help you with that?"
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    if let message = try? JSONDecoder().decode(Message.self, from: data) {
                        DispatchQueue.main.async {
                            self?.receivedMessage = message
                        }
                    }
                case .string(let string):
                    if let data = string.data(using: .utf8),
                       let message = try? JSONDecoder().decode(Message.self, from: data) {
                        DispatchQueue.main.async {
                            self?.receivedMessage = message
                        }
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.error = "Error receiving message: \(error.localizedDescription)"
                    self?.isConnected = false
                    self?.reconnect()
                }
            }
        }
    }
}
