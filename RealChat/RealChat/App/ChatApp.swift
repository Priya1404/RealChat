//
//  ChatApp.swift
//  RealChat
//
//  Created by Priya Srivastava on 02/05/25.
//

import SwiftUI

@main
struct ChatApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var isOnline: Bool = true
    @Published var errorMessage: String?
    
    func showError(_ message: String) {
        errorMessage = message
    }
}
