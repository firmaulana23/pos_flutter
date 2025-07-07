# Coffee POS - Flutter Point of Sale System

A comprehensive Point of Sale (POS) system for coffee shops built with Flutter, designed to work with the POS Server backend API.

## Features

### 🔐 Authentication
- User login/logout
- Role-based access control (Admin, Cashier, Owner)
- Secure token-based authentication

### 📱 Point of Sale
- Browse menu items by category
- Add items to cart with quantities
- Select add-ons for menu items
- Process payments (Cash, Card, Digital Wallet)
- Print receipts (digital format)

### 📊 Dashboard & Analytics
- Real-time sales statistics
- Daily/hourly sales reports
- Top-selling items analysis
- Revenue tracking

### 🍕 Menu Management
- Create, edit, and delete categories
- Manage menu items with images
- Add-on management
- Availability toggle

### 💰 Transaction Management
- View all transactions (All, Pending, Paid)
- Process pending payments
- Transaction details and history

### 👤 User Profile
- View user information
- App settings and logout

## Technology Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider pattern
- **HTTP Client**: http package
- **Local Storage**: SharedPreferences & Flutter Secure Storage
- **Image Caching**: cached_network_image
- **UI Components**: Material Design 3

## Backend API

This app is designed to work with the [POS Server](https://github.com/firmaulana23/pos_server) backend which provides:
- RESTful API endpoints
- Authentication middleware
- Menu and category management
- Transaction processing
- Dashboard analytics

## Project Structure

```
lib/
├── main.dart                 # App entry point with providers
├── models/                   # Data models
│   ├── user.dart
│   ├── menu.dart
│   ├── transaction.dart
│   └── dashboard.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── menu_provider.dart
│   ├── cart_provider.dart
│   ├── transaction_provider.dart
│   └── dashboard_provider.dart
├── services/                 # API services
│   └── api_service.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── main_screen.dart
│   ├── pos_screen.dart
│   ├── dashboard_screen.dart
│   ├── menu_management_screen.dart
│   ├── transactions_screen.dart
│   └── profile_screen.dart
├── widgets/                  # Reusable widgets
│   └── common_widgets.dart
└── utils/                    # Utilities
    ├── formatters.dart
    └── theme.dart
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator
- POS Server backend running

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flutter_pos
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   Update the base URL in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://your-server-url:3000/api';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### VS Code Tasks

The project includes VS Code tasks for common operations:
- `Flutter: Run` - Run the app in debug mode
- `Flutter: Build APK` - Build release APK
- `Flutter: Clean` - Clean build cache
- `Flutter: Pub Get` - Get dependencies
- `Flutter: Doctor` - Check Flutter installation

Access these via `Ctrl+Shift+P` → `Tasks: Run Task`

## Default Credentials

For testing purposes, you can use these demo credentials:
- **Username**: demo
- **Password**: demo123

Note: These credentials work with the demo mode. For production, configure your own authentication system.

## API Endpoints

The app integrates with these main API endpoints:

### Authentication
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout

### Menu Management
- `GET /categories` - Get all categories
- `POST /categories` - Create category
- `PUT /categories/:id` - Update category
- `DELETE /categories/:id` - Delete category
- `GET /menu-items` - Get all menu items
- `POST /menu-items` - Create menu item
- `PUT /menu-items/:id` - Update menu item
- `DELETE /menu-items/:id` - Delete menu item

### Add-ons
- `GET /add-ons` - Get all add-ons
- `POST /add-ons` - Create add-on
- `PUT /add-ons/:id` - Update add-on
- `DELETE /add-ons/:id` - Delete add-on

### Transactions
- `GET /transactions` - Get all transactions
- `POST /transactions` - Create transaction
- `PUT /transactions/:id/pay` - Process payment

### Dashboard
- `GET /dashboard/stats` - Get dashboard statistics
- `GET /dashboard/sales-report` - Get sales report
- `GET /dashboard/top-selling` - Get top selling items

## Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.1.1
  http: ^1.1.0
  shared_preferences: ^2.2.2
  intl: ^0.18.1
  flutter_secure_storage: ^9.0.0
  cached_network_image: ^3.3.0
  flutter_staggered_grid_view: ^0.6.2
  flutter_barcode_scanner: ^2.0.0
  permission_handler: ^11.1.0
  connectivity_plus: ^5.0.1

dev_dependencies:
  flutter_test: sdk: flutter
  flutter_lints: ^3.0.0
  flutter_launcher_icons: ^0.13.1
```

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## Changelog

### v1.0.0
- Initial release
- Complete POS functionality
- Dashboard and analytics
- Menu management system
- Transaction processing
- User authentication

---

**Made with ❤️ using Flutter**
