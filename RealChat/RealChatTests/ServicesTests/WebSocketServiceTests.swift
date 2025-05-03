//
//  WebSocketTests.swift
//  RealChat
//
//  Created by Priya Srivastava on 03/05/25.
//

import XCTest
import Network
@testable import RealChat

class MockWebSocketTask: WebSocketTaskProtocol {
    var sentMessages: [URLSessionWebSocketTask.Message] = []
    var isCancelled = false
    
    func resume() {}
    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isCancelled = true
    }
    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void) {
        sentMessages.append(message)
        completionHandler(nil)
    }
    func sendPing(pongReceiveHandler: @escaping (Error?) -> Void) {
        pongReceiveHandler(nil)
    }
    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
    }
}

class MockNetworkMonitor: NetworkMonitorProtocol {
    var pathUpdateHandler: ((NWPath) -> Void)?
    func start(queue: DispatchQueue) {}
}

class WebSocketServiceTests: XCTestCase {
    
    var service: WebSocketService!
    var mockWebSocket: MockWebSocketTask!
    var mockMonitor: MockNetworkMonitor!
    
    override func setUp() {
        super.setUp()
        mockWebSocket = MockWebSocketTask()
        mockMonitor = MockNetworkMonitor()
        
        service = WebSocketService()
        service.webSocket = mockWebSocket
    }

    func testSendMessage_whenOffline_shouldQueueMessage() {
        service.isNetworkAvailable = false
        let message = Message(content: "Hello", isFromUser: true, status: .sending)
        
        let result = service.send(message)
        
        XCTAssertFalse(result)
        XCTAssertEqual(service.error, "No internet connection. Message queued.")
    }

    func testSendMessage_whenConnected_shouldSendMessage() {
        service.isConnected = true
        service.isNetworkAvailable = true
        let message = Message(content: "Hello", isFromUser: true, status: .sending)
        
        let result = service.send(message)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockWebSocket.sentMessages.count, 1)
    }

    func testConnect_shouldSetIsConnected() {
        service.isNetworkAvailable = true
        service.connect()
        
        XCTAssertTrue(service.isConnected)
    }
    
    func testDisconnect_shouldCancelWebSocketAndSetIsConnectedFalse() {
        service.isConnected = true
        service.disconnect()
        
        XCTAssertFalse(service.isConnected)
        XCTAssertTrue(mockWebSocket.isCancelled)
    }
}
