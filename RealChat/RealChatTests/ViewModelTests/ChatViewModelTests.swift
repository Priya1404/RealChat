//
//  ChatViewModelTests.swift
//  RealChat
//
//  Created by Priya Srivastava on 03/05/25.
//

import XCTest
@testable import RealChat

class ChatViewModelTests: XCTestCase {
    var viewModel: ChatViewModel!
    var mockWebSocketService: MockWebSocketService!
    
    override func setUp() {
        super.setUp()
        mockWebSocketService = MockWebSocketService()
        viewModel = ChatViewModel(webSocketService: mockWebSocketService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockWebSocketService = nil
        super.tearDown()
    }
    
    func testSendMessageOnline() {
        viewModel.createNewChat()
        mockWebSocketService.isNetworkAvailable = true
        mockWebSocketService.isConnected = true
        
        viewModel.sendMessage("Hello")
        
        XCTAssertEqual(viewModel.currentChat?.messages.count, 2)
        let userMessage = viewModel.currentChat?.messages[1]
        XCTAssertEqual(userMessage?.content, "Hello")
        XCTAssertTrue(userMessage?.isFromUser ?? false)
        XCTAssertEqual(userMessage?.status, .sent)
    }
    
    func testSendMessageOffline() {
        viewModel.createNewChat()
        mockWebSocketService.isNetworkAvailable = false
        
        viewModel.sendMessage("Hello")
        
        XCTAssertEqual(viewModel.currentChat?.messages.count, 2)
        let userMessage = viewModel.currentChat?.messages[1]
        XCTAssertEqual(userMessage?.content, "Hello")
        XCTAssertTrue(userMessage?.isFromUser ?? false)
        XCTAssertEqual(userMessage?.status, .failed)
    }
}

class MockWebSocketService: WebSocketService {
    override var isNetworkAvailable: Bool {
        get { _isNetworkAvailable }
        set {
            _isNetworkAvailable = newValue
            objectWillChange.send()
        }
    }
    
    override var isConnected: Bool {
        get { _isConnected }
        set {
            _isConnected = newValue
            objectWillChange.send()
        }
    }
    
    private var _isNetworkAvailable: Bool = true
    private var _isConnected: Bool = true
    
    var messageQueue: [Message] = []

    func simulateReceivedMessage(_ message: Message) {
        receivedMessage = message
    }

    func simulateError(_ error: String) {
        self.error = error
    }

    func simulateNetworkStatusChange(isAvailable: Bool) {
        self.isNetworkAvailable = isAvailable
    }

    override func send(_ message: Message) -> Bool {
        if !isNetworkAvailable {
            messageQueue.append(message)
            return false
        }
        return true
    }
}
