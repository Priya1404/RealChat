# Real-Time Chat Application

A professional iOS chat application that demonstrates real-time communication capabilities with offline support.

## Features

- Real-time chat interface using WebSocket
- Offline message queuing and automatic retry
- Clean, modern UI following iOS design guidelines
- Robust error handling and user feedback
- Message preview and unread status
- Automatic reconnection handling

## Technical Stack

- Swift 5.0+
- iOS 15.0+
- WebSocket for real-time communication
- CoreData for local storage
- Combine framework for reactive programming
- MVVM architecture pattern

## Project Structure

```
ChatApp/
├── App/
│   ├── ChatApp.swift
│   └── AppDelegate.swift
├── Features/
│   ├── Chat/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   └── Common/
├── Services/
│   ├── NetworkService/
│   ├── WebSocketService/
│   └── StorageService/
└── Utils/
    ├── Extensions/
    └── Helpers/
```

## Setup Instructions

1. Clone the repository
2. Open `ChatApp.xcodeproj` in Xcode 13.0 or later
3. Install dependencies using Swift Package Manager
4. Build and run the project

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.0+

## Architecture

The application follows the MVVM (Model-View-ViewModel) architecture pattern with the following components:

- **Models**: Data structures and business logic
- **Views**: UI components and user interaction
- **ViewModels**: Business logic and data transformation
- **Services**: Network, storage, and other external services

## Testing

The project includes unit tests for core functionality and UI tests for critical user flows.

## License

MIT License
