import XCTest
@testable import RealChat

//class ChatViewModelTests: XCTestCase {
//    var viewModel: ChatViewModel!
//    var mockWebSocketService: MockWebSocketService!
//    
//    override func setUp() {
//        super.setUp()
//        mockWebSocketService = MockWebSocketService()
//        viewModel = ChatViewModel(webSocketService: mockWebSocketService)
//    }
//    
//    override func tearDown() {
//        viewModel = nil
//        mockWebSocketService = nil
//        super.tearDown()
//    }
//    
//    func testInitialState() {
//        XCTAssertFalse(viewModel.isOffline)
//        XCTAssertNil(viewModel.error)
//        XCTAssertFalse(viewModel.showError)
//        XCTAssertTrue(viewModel.chats.isEmpty)
//        XCTAssertNil(viewModel.currentChat)
//    }
//    
//    func testCreateNewChat() {
//        viewModel.createNewChat()
//        
//        XCTAssertEqual(viewModel.chats.count, 1)
//        XCTAssertNotNil(viewModel.currentChat)
//        XCTAssertEqual(viewModel.currentChat?.messages.count, 1)
//        XCTAssertFalse(viewModel.currentChat?.messages[0].isFromUser ?? true)
//    }
//    
//    func testSendMessageOnline() {
//        // Setup
//        viewModel.createNewChat()
//        mockWebSocketService.isNetworkAvailable = true
//        mockWebSocketService.isConnected = true
//        
//        // Test
//        viewModel.sendMessage("Hello")
//        
//        // Verify
//        XCTAssertEqual(viewModel.currentChat?.messages.count, 2)
//        let userMessage = viewModel.currentChat?.messages[1]
//        XCTAssertEqual(userMessage?.content, "Hello")
//        XCTAssertTrue(userMessage?.isFromUser ?? false)
//        XCTAssertEqual(userMessage?.status, .sent)
//    }
//    
//    func testSendMessageOffline() {
//        // Setup
//        viewModel.createNewChat()
//        mockWebSocketService.isNetworkAvailable = false
//        
//        // Test
//        viewModel.sendMessage("Hello")
//        
//        // Verify
//        XCTAssertEqual(viewModel.currentChat?.messages.count, 2)
//        let userMessage = viewModel.currentChat?.messages[1]
//        XCTAssertEqual(userMessage?.content, "Hello")
//        XCTAssertTrue(userMessage?.isFromUser ?? false)
//        XCTAssertEqual(userMessage?.status, .failed)
//    }
//    
//    func testMessageStatusProgression() {
//        // Setup
//        viewModel.createNewChat()
//        mockWebSocketService.isNetworkAvailable = true
//        mockWebSocketService.isConnected = true
//        
//        // Test
//        viewModel.sendMessage("Hello")
//        
//        // Verify initial status
//        XCTAssertEqual(viewModel.currentChat?.messages[1].status, .sent)
//        
//        // Simulate receiving bot response
//        let botMessage = Message(content: "Hi there!", isFromUser: false, status: .delivered)
//        mockWebSocketService.simulateReceivedMessage(botMessage)
//        
//        // Verify final status
//        XCTAssertEqual(viewModel.currentChat?.messages[1].status, .delivered)
//    }
//    
//    func testOfflineToOnlineTransition() {
//        // Setup
//        viewModel.createNewChat()
//        mockWebSocketService.isNetworkAvailable = false
//        
//        // Send message while offline
//        viewModel.sendMessage("Hello")
//        XCTAssertEqual(viewModel.currentChat?.messages[1].status, .failed)
//        
//        // Simulate coming back online
//        mockWebSocketService.isNetworkAvailable = true
//        mockWebSocketService.isConnected = true
//        mockWebSocketService.simulateNetworkStatusChange(isAvailable: true)
//        
//        // Verify message status updates
//        XCTAssertEqual(viewModel.currentChat?.messages[1].status, .sent)
//    }
//    
//    func testErrorHandling() {
//        // Setup
//        viewModel.createNewChat()
//        
//        // Simulate error
//        mockWebSocketService.simulateError("Test error")
//        
//        // Verify
//        XCTAssertEqual(viewModel.error, "Test error")
//        XCTAssertTrue(viewModel.showError)
//    }
//    
//    func testAlertCooldown() {
//        // Setup
//        viewModel.createNewChat()
//        
//        // First error
//        mockWebSocketService.simulateError("First error")
//        XCTAssertEqual(viewModel.error, "First error")
//        
//        // Second error immediately
//        mockWebSocketService.simulateError("Second error")
//        XCTAssertEqual(viewModel.error, "First error") // Should not change
//        
//        // Wait for cooldown
//        let expectation = XCTestExpectation(description: "Wait for cooldown")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 31) {
//            self.mockWebSocketService.simulateError("Third error")
//            XCTAssertEqual(self.viewModel.error, "Third error")
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 32)
//    }
//}
//
//// MARK: - Mock WebSocket Service
////class MockWebSocketService: WebSocketService {
////    var isNetworkAvailable: Bool = true
////    var isConnected: Bool = true
////    var messageQueue: [Message] = []
////    
////    func simulateReceivedMessage(_ message: Message) {
////        receivedMessage = message
////    }
////    
////    func simulateError(_ error: String) {
////        self.error = error
////    }
////    
////    func simulateNetworkStatusChange(isAvailable: Bool) {
////        self.isNetworkAvailable = isAvailable
////        // Notify observers
////        objectWillChange.send()
////    }
////    
////    override func send(_ message: Message) -> Bool {
////        if !isNetworkAvailable {
////            messageQueue.append(message)
////            return false
////        }
////        return true
////    }
////} 
//
//class MockWebSocketService: WebSocketService {
//    override var isNetworkAvailable: Bool {
//        get { _isNetworkAvailable }
//        set {
//            _isNetworkAvailable = newValue
//            objectWillChange.send()
//        }
//    }
//    
//    override var isConnected: Bool {
//        get { _isConnected }
//        set {
//            _isConnected = newValue
//            objectWillChange.send()
//        }
//    }
//    
//    private var _isNetworkAvailable: Bool = true
//    private var _isConnected: Bool = true
//    
//    var messageQueue: [Message] = []
//
//    func simulateReceivedMessage(_ message: Message) {
//        receivedMessage = message
//    }
//
//    func simulateError(_ error: String) {
//        self.error = error
//    }
//
//    func simulateNetworkStatusChange(isAvailable: Bool) {
//        self.isNetworkAvailable = isAvailable
//    }
//
//    override func send(_ message: Message) -> Bool {
//        if !isNetworkAvailable {
//            messageQueue.append(message)
//            return false
//        }
//        return true
//    }
//}

import XCTest
@testable import RealChat

class MockWebSocketService: WebSocketService {
    var mockIsConnected: Bool = true
    var mockIsNetworkAvailable: Bool = true
    var mockSendShouldSucceed = true
    
    override var isConnected: Bool { mockIsConnected }
    override var isNetworkAvailable: Bool { mockIsNetworkAvailable }
    
    override func send(_ message: Message) -> Bool {
        return mockSendShouldSucceed
    }

    func simulateIncomingMessage(_ message: Message) {
        receivedMessage = message
    }

    func simulateError(_ errorMessage: String) {
        error = errorMessage
    }

    func simulateNetworkChange(isAvailable: Bool) {
        isNetworkAvailable = isAvailable
    }
}

final class ChatViewModelTests: XCTestCase {
    var viewModel: ChatViewModel!
    var mockWebSocket: MockWebSocketService!

    override func setUp() {
        super.setUp()
        mockWebSocket = MockWebSocketService()
        viewModel = ChatViewModel(webSocketService: mockWebSocket)
    }

    func testCreateNewChatAddsChat() {
        let initialCount = viewModel.chats.count
        viewModel.createNewChat()
        XCTAssertEqual(viewModel.chats.count, initialCount + 1)
        XCTAssertNotNil(viewModel.currentChat)
    }

    func testSendMessageWhenOnline() {
        viewModel.createNewChat()
        let chatId = viewModel.currentChat?.id
        viewModel.sendMessage("Hi")

        guard let chat = viewModel.chats.first(where: { $0.id == chatId }),
              let message = chat.messages.last else {
            XCTFail("Message not found")
            return
        }

        XCTAssertEqual(message.content, "Hi")
        XCTAssertEqual(message.status, .sent)
    }

    func testSendMessageWhenOffline() {
        mockWebSocket.mockSendShouldSucceed = false
        mockWebSocket.mockIsNetworkAvailable = false
        viewModel.createNewChat()
        viewModel.sendMessage("Offline message")

        let message = viewModel.currentChat?.messages.last
        XCTAssertEqual(message?.content, "Offline message")
        XCTAssertEqual(message?.status, .failed)
    }

    func testHandleReceivedMessageAppendsMessage() {
        viewModel.createNewChat()
        let initialCount = viewModel.currentChat?.messages.count ?? 0
        let incomingMessage = Message(content: "Hello from server", isFromUser: false, status: .delivered)
        mockWebSocket.simulateIncomingMessage(incomingMessage)

        let updatedCount = viewModel.currentChat?.messages.count ?? 0
        XCTAssertEqual(updatedCount, initialCount + 1)
        XCTAssertEqual(viewModel.currentChat?.messages.last?.content, "Hello from server")
    }

    func testShowErrorAndCooldown() {
        viewModel.createNewChat()
        viewModel.sendMessage("First message")
        mockWebSocket.simulateError("Socket failed")

        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.error, "Socket failed")

        // Call again within cooldown
        viewModel.sendMessage("Second message")
        mockWebSocket.simulateError("Another failure")
        XCTAssertEqual(viewModel.error, "Socket failed", "Error message should not update within cooldown")
    }

    func testSelectChatUpdatesCurrent() {
        viewModel.createNewChat()
        let newChat = viewModel.chats.last!
        viewModel.selectChat(newChat)
        XCTAssertEqual(viewModel.currentChat?.id, newChat.id)
    }

    func testUpdateMessageStatus() {
        viewModel.createNewChat()
        viewModel.sendMessage("Update me")

        guard let message = viewModel.currentChat?.messages.last else {
            XCTFail("Message not found")
            return
        }

        viewModel.updateMessageStatus(message.id, status: .delivered)
        XCTAssertEqual(viewModel.currentChat?.messages.last?.status, .delivered)
    }

    func testOfflineToOnlineMessageRecovery() {
        viewModel.createNewChat()
        mockWebSocket.mockSendShouldSucceed = false
        viewModel.sendMessage("This will fail")

        let failedMessage = viewModel.currentChat?.messages.last
        XCTAssertEqual(failedMessage?.status, .failed)

        // Simulate going back online
        mockWebSocket.mockSendShouldSucceed = true
        mockWebSocket.simulateNetworkChange(isAvailable: true)
        viewModel.updateAllFailedMessagesToDelivered()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let updatedMessage = self.viewModel.currentChat?.messages.last
            XCTAssertEqual(updatedMessage?.status, .delivered)
        }
    }
}
