# Cellaris (MBM Client)

Cellaris is a premium, offline-first business management client application built with Flutter. It serves as the primary interface for users, providing Point of Sale (POS), Inventory Management, and other operational tools.

This project is part of the **Mobile Business Manager (MBM)** suite.

---

## 🚀 Key Features

*   **Offline-First Architecture**: Uses [Isar Database](https://isar.dev/) for local data storage, allowing full functionality without an internet connection.
*   **Secure Access Control**: Robust "Access Guard" system that validates user subscription status, offline day limits, and safeguards against device time tampering.
*   **Cross-Platform**: Runs natively on Linux, Windows, macOS, Android, iOS, and Web.
*   **Hybrid Firebase Integration**: Innovative architecture to support Firebase Authentication and Cloud Firestore across all platforms, including Linux Desktop.

---

## 🛠 Technical Architecture

Cellaris uses a modern tech stack centered improving developer experience and application performance.

*   **Framework**: Flutter (Dart)
*   **State Management**: Riverpod
*   **Routing**: GoRouter
*   **Local Database**: Isar (High-performance NoSQL)
*   **Backend**: Firebase (Auth & Firestore)

### 🖥️ Desktop (Linux/Windows) Implementation Strategy

A key challenge in Flutter development is Firebase support on desktop Linux. Cellaris solves this with a **Hybrid Architecture**:

1.  **Authentication**: Uses `firebase_dart` (a pure Dart implementation) to handle Firebase Authentication on Windows and Linux.
2.  **Database (Firestore)**:
    *   **Web/Mobile**: Uses the official `cloud_firestore` package for native performance and real-time streams.
    *   **Desktop**: Uses a custom **`FirestoreRestClient`** that communicates directly with the Firestore REST API. This bypasses the lack of native plugin support on Linux.

> **Note**: This architecture is fully abstracted behind platform-aware services (`AuthService`, `AccessGuardService`), so the UI layer remains unaware of the underlying implementation.

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── database/           # Isar schema and local storage logic
│   ├── models/             # Data models (UserControlDocument, AppUser)
│   ├── repositories/       # Data access layer (LocalControlStateRepository, ProductRepository)
│   ├── services/
│   │   ├── access_guard_service.dart   # Core access control logic
│   │   ├── auth_service.dart           # Platform-aware Auth implementation
│   │   ├── firestore_rest_client.dart  # Custom REST client for Desktop
│   │   ├── subscription_service.dart   # Subscription validation
│   │   └── sync_service.dart           # Data synchronization logic
│   └── widgets/            # Reusable UI components
├── features/
│   ├── auth/               # Login, Signup, Verification screens
│   ├── dashboard/          # Main application dashboard
│   ├── settings/           # User settings
│   └── ...
└── main.dart               # Entry point with platform-specific initialization
```

---

## ⚙️ Setup & Prerequisites

### 1. Flutter Environment
Ensure you have the latest stable version of Flutter installed.

```bash
flutter doctor
```

### 2. Linux Dependencies
For Linux development, you need the following system libraries:

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev libnm-dev
```

*   `libsecret-1-dev`: Required for secure storage (Auth tokens).
*   `libnm-dev`: Required for `connectivity_plus` (Network status).

---

## ▶️ Running the Application

### Option 1: Using the Runner Script (Recommended)
Use the provided `run.sh` script in the root `MBM` directory:

```bash
./run.sh
```
Select **Option 1** to run the Cellaris Client on Linux Desktop.

### Option 2: Manual Execution
Navigate to the `cellaris` directory and run:

```bash
cd cellaris
flutter pub get
flutter run -d linux
```

---

## ⚠️ Known Limitations (Desktop)

Due to the use of the REST API for Firestore on Linux/Windows:

1.  **Real-time Updates**: The desktop client does **not** support real-time document streaming (listeners) for Firestore data.
    *   *Impact*: If an Admin approves a user request, the Desktop client will not update instantly.
    *   *Workaround*: You must **refresh** or **restart** the application to fetch the latest status from the server.
2.  **Server Timestamps**: Writing data from Desktop relies on the client's system time for "server timestamps" in some instances.

---

## 🐛 Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
*   **Cause**: This usually happens if a service tries to use `FirebaseFirestore.instance` (FlutterFire) on a desktop platform where it's not initialized.
*   **Fix**: Ensure you are using the platform-aware services (`AuthService`, `AccessGuardService`) which handle the redirection to `FirestoreRestClient` on desktop.

### "RenderFlex overflowed"
*   **Status**: Fixed. If encountered on the 'Connection Error' screen, update to the latest version.

### Authentication Persistance
*   `firebase_dart` uses Hive for local storage. If you find yourself logged out frequently, ensure the app has write permissions to its local directory.
