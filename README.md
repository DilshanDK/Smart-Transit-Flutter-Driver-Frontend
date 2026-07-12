# 🚌 Smart Transit System - Driver App

This repository contains the Driver Mobile Application for the Smart Transit System, built with **Flutter**. Designed specifically for transit operators, this app allows drivers to broadcast their live location, manage routes, and validate passenger tickets seamlessly.

## 🚀 Features
- **Live GPS Broadcasting:** Connects to the backend via WebSockets to stream real-time geographical coordinates and heading data to the server.
- **QR Ticket Scanner:** Built-in camera integration to quickly scan and validate passenger QR tickets upon boarding, checking for authenticity and expiration.
- **Active Route Management:** View assigned routes, start/end journeys, and monitor current passenger manifest counts.
- **Push Notifications:** Receive dispatch alerts or route updates directly from administrators via Firebase Cloud Messaging.

## 💻 Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** BLoC / Provider
- **Networking/Real-time:** Dio, Socket.io-client
- **Hardware Integrations:** Location/GPS services, Camera (QR Scanning)
- **Push Notifications:** Firebase

## 🛠️ Installation & Setup

1. **Clone the repository**
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Configure Environment Variables**
   Create a `.env` file in the root directory linking to the backend API.
4. **Run the application**
   ```bash
   flutter run
   ```
