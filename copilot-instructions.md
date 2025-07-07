# Copilot Instructions for Flutter POS Project

## Project Overview

This is a Flutter-based Point of Sale (POS) system for coffee shops that integrates with a Node.js backend API. The app follows a clean architecture with Provider state management and Material Design 3 UI components.

## Key Architecture Patterns

### State Management
- **Provider Pattern**: Used for all state management
- **Separation of Concerns**: Providers handle business logic, widgets handle UI
- **Reactive UI**: Widgets rebuild automatically when state changes

### Folder Structure
```
lib/
├── main.dart                 # App entry point with MultiProvider setup
├── models/                   # Data classes with JSON serialization
├── providers/                # State management with ChangeNotifier
├── services/                 # API communication and external services
├── screens/                  # Full-screen UI components
├── widgets/                  # Reusable UI components
└── utils/                    # Helper functions and constants
```

## Development Guidelines

### Code Style
- Follow Dart style guide and use `flutter_lints`
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Prefer composition over inheritance for widgets

### State Management
- Extend `ChangeNotifier` for providers
- Use `Consumer` and `Provider.of` for accessing state
- Call `notifyListeners()` after state changes
- Handle loading and error states consistently

### API Integration
- All HTTP requests go through `ApiService`
- Use try-catch blocks for error handling
- Include proper authentication headers
- Handle network connectivity issues

### UI Components
- Use Material Design 3 components
- Follow the established theme in `utils/theme.dart`
- Create reusable widgets in `widgets/common_widgets.dart`
- Implement proper loading and error states

## Common Patterns

### Provider Usage
```dart
// In widget
Consumer<MenuProvider>(
  builder: (context, menuProvider, child) {
    if (menuProvider.isLoading) return LoadingWidget();
    if (menuProvider.error != null) return ErrorWidget(message: menuProvider.error!);
    return YourWidget();
  },
)

// For actions
final provider = Provider.of<MenuProvider>(context, listen: false);
await provider.loadMenuItems();
```

### API Service Calls
```dart
Future<void> loadData() async {
  try {
    setLoading(true);
    final response = await _apiService.getData();
    _data = response;
    _error = null;
  } catch (e) {
    _error = e.toString();
  } finally {
    setLoading(false);
    notifyListeners();
  }
}
```

### Widget Structure
```dart
class CustomWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  
  const CustomWidget({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: ListTile(
        title: Text(title),
        onTap: onTap,
      ),
    );
  }
}
```

## Key Features Implementation

### Authentication Flow
1. `SplashScreen` checks authentication status
2. Navigate to `LoginScreen` or `MainScreen`
3. `AuthProvider` manages user state and tokens
4. Protected routes check authentication

### POS Workflow
1. Browse menu items by category
2. Add items to cart with `CartProvider`
3. Select add-ons and quantities
4. Process payment through `TransactionProvider`
5. Generate transaction record

### Menu Management
1. CRUD operations for categories and menu items
2. Image upload and caching
3. Availability toggle functionality
4. Real-time UI updates

### Dashboard Analytics
1. Fetch statistics from API
2. Display charts and metrics
3. Date-based filtering
4. Real-time data refresh

## Testing Guidelines

### Widget Tests
- Test widget rendering with different states
- Mock providers using `MockProvider`
- Test user interactions and navigation
- Verify error and loading states

### Integration Tests
- Test complete user flows
- Mock HTTP responses
- Test offline scenarios
- Verify data persistence

## Performance Considerations

### Memory Management
- Dispose controllers and streams properly
- Use `const` constructors where possible
- Implement lazy loading for large lists
- Cache network images effectively

### Network Optimization
- Implement proper retry mechanisms
- Use connection timeouts
- Cache frequently accessed data
- Optimize payload sizes

## Security Best Practices

### Authentication
- Store tokens securely using `flutter_secure_storage`
- Implement proper logout functionality
- Handle token expiration gracefully
- Validate user permissions client-side

### Data Handling
- Sanitize user inputs
- Validate API responses
- Handle sensitive data appropriately
- Implement proper error messages

## Common Issues and Solutions

### State Management
- **Issue**: UI not updating after state change
- **Solution**: Ensure `notifyListeners()` is called and widget uses `Consumer`

### API Integration
- **Issue**: Network requests failing
- **Solution**: Check API endpoint, authentication headers, and network connectivity

### Navigation
- **Issue**: Context errors during navigation
- **Solution**: Use `mounted` check before navigation and proper BuildContext

### Performance
- **Issue**: Slow list rendering
- **Solution**: Implement lazy loading, use `ListView.builder`, and optimize widget builds

## Dependencies and Packages

### Core Dependencies
- `provider` - State management
- `http` - HTTP client
- `shared_preferences` - Local storage
- `flutter_secure_storage` - Secure token storage

### UI Dependencies
- `cached_network_image` - Image caching
- `flutter_staggered_grid_view` - Grid layouts
- `intl` - Internationalization and formatting

### Development Dependencies
- `flutter_lints` - Code linting
- `flutter_test` - Testing framework

## API Integration Details

### Base Configuration
```dart
static const String baseUrl = 'http://localhost:3000/api';
static const Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};
```

### Authentication Header
```dart
Map<String, String> get authHeaders => {
  ...headers,
  if (authToken != null) 'Authorization': 'Bearer $authToken',
};
```

### Error Handling
```dart
if (response.statusCode == 200) {
  return jsonDecode(response.body);
} else if (response.statusCode == 401) {
  throw Exception('Unauthorized access');
} else {
  throw Exception('HTTP ${response.statusCode}: ${response.body}');
}
```

## Deployment and Building

### Debug Build
```bash
flutter run --debug
```

### Release Build
```bash
flutter build apk --release
flutter build appbundle --release
```

### Environment Configuration
- Update API endpoints for different environments
- Configure app signing for release builds
- Set up proper build variants

## Future Enhancements

### Planned Features
- Offline functionality with local database
- Barcode scanning for inventory
- Multi-language support
- Push notifications
- Advanced reporting and analytics

### Technical Improvements
- Add unit tests coverage
- Implement CI/CD pipeline
- Add performance monitoring
- Enhance error reporting

## Troubleshooting

### Common Build Issues
1. **Flutter SDK version mismatch**: Update Flutter to latest stable
2. **Dependency conflicts**: Run `flutter pub deps` to check dependencies
3. **Platform-specific errors**: Check Android/iOS specific configurations

### Runtime Issues
1. **Network connectivity**: Implement proper connection checking
2. **Memory leaks**: Use proper disposal in StatefulWidgets
3. **Performance issues**: Profile app using Flutter DevTools

---

This project follows Flutter best practices and maintains a clean, scalable architecture. When making changes, ensure you follow the established patterns and update tests accordingly.
