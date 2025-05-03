//
//  ContentView.swift
//  RealChat
//
//  Created by Priya Srivastava on 02/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var messageText = ""
    @State private var showingChatDetail = false
    @State private var showingNewChat = false
    @State private var alertItem: AlertItem? = nil

    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Chats")
                .navigationBarItems(trailing: composeButton)
                .alert(item: $alertItem) { alertItem in
                    Alert(
                        title: Text("Connection Error"),
                        message: Text(alertItem.message),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .sheet(isPresented: $showingChatDetail) {
                    if let chat = viewModel.currentChat {
                        ChatDetailView(viewModel: viewModel)
                    }
                }
        }
        .onAppear { viewModel.connect() }
        .onDisappear { viewModel.disconnect() }
    }
    
    private var contentView: some View {
        VStack {
            if viewModel.isOffline {
                offlineView
            } else if viewModel.chats.isEmpty {
                emptyStateView
            } else {
                chatListView
            }
        }
        .onChange(of: viewModel.error) { error in
            if let error = error {
                alertItem = AlertItem(message: error)
                viewModel.error = nil
            }
        }
    }
    
    private var composeButton: some View {
        Button(action: {
            let newChat = viewModel.createNewChat()
            viewModel.selectChat(newChat) // Ensure it's set as current
            showingChatDetail = true
        }) {
            Image(systemName: "square.and.pencil")
        }
    }
    
    private var offlineView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Internet Connection")
                .font(.title2)
                .foregroundColor(.gray)
            Text("Messages will be queued and sent when you're back online")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Chats Available")
                .font(.title2)
                .foregroundColor(.gray)
            Text("Start a new conversation by tapping the compose button")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: {
                viewModel.createNewChat()
                showingNewChat = true
            }) {
                Text("New Chat")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
    }
    
    private var chatListView: some View {
        List {
            ForEach(viewModel.chats) { chat in
                ChatRowView(chat: chat) {
                    viewModel.selectChat(chat)
                    showingChatDetail = true
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct ChatRowView: View {
    let chat: Chat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.preview)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(chat.lastUpdated, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if chat.shouldShowUnreadCount {
                    Text("\(chat.unreadCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
