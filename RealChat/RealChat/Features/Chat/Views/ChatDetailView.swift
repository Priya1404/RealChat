//
//  ChatDetailView.swift
//  RealChat
//
//  Created by Priya Srivastava on 02/05/25.
//

import SwiftUI

struct ChatDetailView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var messageText = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Text("Chat")
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.currentChat?.messages ?? []) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom(animated: false)
                }
                .onChange(of: viewModel.currentChat?.messages.count) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToBottom(animated: true)
                    }
                }
                .onChange(of: keyboardHeight) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToBottom(animated: true)
                    }
                }
            }
            
            // Input area
            VStack(spacing: 0) {
                Divider()
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.error ?? "An error occurred"),
                dismissButton: .default(Text("OK")) {
                    viewModel.dismissError()
                }
            )
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        viewModel.sendMessage(trimmedMessage)
        messageText = ""
    }
    
    private func scrollToBottom(animated: Bool) {
        guard let lastMessage = viewModel.currentChat?.messages.last else { return }
        withAnimation(animated ? .easeOut(duration: 0.3) : nil) {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self)
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading) {
                Text(message.content)
                    .padding(12)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)
                
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if message.isFromUser {
                        Image(systemName: messageStatusIcon)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
    
    private var messageStatusIcon: String {
        switch message.status {
        case .sending:
            return "clock"
        case .sent:
            return "checkmark"
        case .delivered:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.circle"
        }
    }
}
