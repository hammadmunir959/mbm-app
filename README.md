# Cellaris

<p align="center">
  <strong>Premium Offline-First Point of Sale & Business Management System</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#license">License</a>
</p>

---

## Overview

**Cellaris** is a feature-rich, offline-first business management application built with Flutter. Designed for mobile phone shops, electronics retailers, and general businesses, it provides a complete suite of tools including Point of Sale (POS), Inventory Management, Repairs Tracking, Customer Management, and Financial Accounting.

> 🚀 **v0.0.5** - Latest release with enhanced Inventory Hub, Buyback Auto-Listing, and improved UI/UX.

---

## Features

### 💰 Point of Sale (POS)
- Quick sales with barcode/IMEI scanning
- Cart management with discounts
- Multiple payment methods (Cash, Card, Credit)
- Invoice generation and printing
- Returns processing with deductions

### 📦 Inventory Management
- **All Products** - List/Grid views, stock filtering, profit margin display
- **Low Stock Alerts** - Automated reorder suggestions, batch PO creation
- **Purchase Orders** - Supplier management, receiving workflow
- **Buyback System** - Used phone purchases with CNIC/phone image capture, auto-listing to inventory

### 🔧 Repairs & Services
- Kanban-style repair tracking (Received → In Repair → Ready → Delivered)
- Priority badges for urgent repairs
- Status updates with timestamps
- Customer notifications

### 👥 Customer & Supplier Management
- Customer profiles with purchase history
- Wholesale vs retail pricing
- Supplier directory with order history
- Credit account management

### 📊 Dashboard & Analytics
- Real-time sales statistics
- 7-day revenue charts
- Monthly summaries
- Quick action buttons

### 💼 Accounting
- Chart of Accounts
- Voucher management (Journal, Receipt, Payment)
- Transaction history with filtering
- Financial reports

### 🔐 Subscription & Security
- Secure Firebase Authentication
- Subscription-based access control
- Offline days tracking
- Device time tampering protection

---

## Installation

### Prerequisites

- **Flutter** 3.19+ (stable channel)
- **Dart** 3.3+

#### Linux Dependencies
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev libnm-dev
```

#### Windows Dependencies
- Visual Studio 2022 with C++ Desktop Development workload

### Quick Start

```bash
# Clone the repository
git clone https://github.com/hammadmunir959/cellaris-app.git
cd cellaris-app

# Install dependencies
flutter pub get

# Run on Linux
flutter run -d linux

# Run on Windows
flutter run -d windows
```

### Build Release

```bash
# Linux
flutter build linux --release

# Windows
flutter build windows --release
```

---

## Architecture

### Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Routing | GoRouter |
| Local Database | Isar (NoSQL) |
| Backend | Firebase (Auth & Firestore) |
| Icons | Lucide Icons |

### Project Structure

```
lib/
├── core/
│   ├── database/           # Isar schema and local storage
│   ├── models/             # Domain models
│   ├── repositories/       # Data access layer
│   ├── services/           # Business logic services
│   └── widgets/            # Reusable UI components
├── features/
│   ├── auth/               # Authentication screens
│   ├── dashboard/          # Main dashboard
│   ├── sales/              # POS and cart
│   ├── inventory/          # Products, PO, Buyback
│   ├── repairs/            # Repair tracking
│   ├── customers/          # Customer management
│   ├── suppliers/          # Supplier management
│   ├── accounts/           # Financial accounting
│   └── transactions/       # Transaction history
├── navigation/             # App routing
├── shared/                 # Shared controllers & widgets
└── main.dart               # Application entry point
```

### Desktop Firebase Strategy

Cellaris uses a **Hybrid Architecture** for Firebase on desktop:

| Platform | Authentication | Firestore |
|----------|----------------|-----------|
| Web/Mobile | Native FlutterFire | Native FlutterFire |
| Desktop | `firebase_dart` | REST API Client |

This approach enables full Firebase functionality on Linux and Windows without native plugin support.

---

## Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| 🐧 Linux | ✅ Supported | Primary development platform |
| 🪟 Windows | ✅ Supported | Fully tested |
| 🍎 macOS | 🔄 Untested | Should work with minor adjustments |
| 📱 Android | ⚠️ Possible | Requires FlutterFire setup |
| 📱 iOS | ⚠️ Possible | Requires FlutterFire setup |
| 🌐 Web | ⚠️ Limited | Some features may not work |

---

## Releases

| Version | Date | Highlights |
|---------|------|------------|
| v0.0.5 | Jan 2026 | Enhanced Inventory Hub, Buyback auto-listing, Repairs Kanban |
| v0.0.2 | Dec 2025 | Dashboard redesign, Transaction history |
| v0.0.1 | Dec 2025 | Initial release |

### Download

Pre-built binaries are available on the [Releases](https://github.com/hammadmunir959/cellaris-app/releases) page:
- `Cellaris-Linux.tar.gz` - Linux x64
- `Cellaris-Windows.zip` - Windows x64

---

## Known Limitations

### Desktop (Linux/Windows)
1. **No Real-time Updates** - Firestore changes require manual refresh
2. **Server Timestamps** - Uses client time for some operations

### General
- Offline sync currently one-way (local → server)
- Some reports require internet connection

---

## Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
- Ensure you're using platform-aware services, not direct FlutterFire calls

### Authentication Issues on Linux
- Check that `libsecret-1-dev` is installed for secure token storage

### Hot Reload Issues
- Use **Hot Restart** (`R`) instead of hot reload (`r`) after class structure changes

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## License

This project is proprietary software. All rights reserved.

© 2025-2026 CodeKonix / Hammad Munir

---

<p align="center">
  Built with ❤️ using Flutter
</p>
