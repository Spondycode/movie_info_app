# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

A Flutter mobile application that fetches and displays movie information from the OMDB API. Users can browse IMDB, fetch movie details by ID/URL, view their search history, and export movie data as Markdown.

## Development Commands

### Running the App
```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# List available devices
flutter devices

# Hot reload during development
# Press 'r' in terminal while app is running

# Hot restart (full app restart)
# Press 'R' in terminal while app is running
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build for iOS
flutter build ios

# Build for release
flutter build apk --release
flutter build ios --release
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage

# Watch mode (re-run on changes)
flutter test --watch
```

**Note:** The current test suite contains a default widget test that needs updating to match the actual app structure (references non-existent `MyApp` widget).

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format all Dart files
dart format .

# Format specific file
dart format lib/main.dart
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Generate app icons (when icon files change in assets/icon/)
flutter pub run flutter_launcher_icons
```

### Cleaning
```bash
# Clean build artifacts
flutter clean

# Clean and reinstall dependencies
flutter clean && flutter pub get
```

## Architecture

### Application Structure

**Navigation Flow:**
- Bottom navigation bar with 4 main pages (Settings → Search → Fetch → History)
- On first launch without API key, app automatically navigates to Settings

**State Management:**
- Uses StatefulWidget for local page-level state
- No global state management (provider/bloc/riverpod)
- Services are instantiated directly in widgets

### Core Components

#### Pages (`lib/pages/`)
- **SettingsPage**: OMDB API key configuration and validation
- **SearchPage**: Embedded WebView for browsing IMDB
- **FetchPage**: Input IMDB ID/URL to fetch movie data; auto-populates from clipboard
- **ListPage**: Display and manage movie search history (up to 50 entries)

#### Services (`lib/services/`)
- **OmdbService**: HTTP client for OMDB API; handles ID extraction from URLs
- **SettingsService**: Persistent storage for API key using SharedPreferences
- **MovieHistoryService**: Manages movie history with deduplication and size limits
- **ClipboardService**: Clipboard read/write operations

#### Models (`lib/models/`)
- **Movie**: Core data model with OMDB field mapping
  - `fromJson()`: Deserialize OMDB API response
  - `toJson()`: Serialize for local storage
  - `toMarkdown()`: Format movie data as Markdown for clipboard export

### Key Patterns

**Data Flow:**
1. User inputs IMDB ID/URL in FetchPage
2. OmdbService extracts clean ID and calls API
3. Movie data converted to Markdown and copied to clipboard
4. Movie saved to history (most recent first, duplicates removed)
5. History displayed in ListPage with poster thumbnails

**Clipboard Integration:**
- FetchPage auto-checks clipboard on load for IMDB URLs
- All fetched movies automatically copied as Markdown
- Users can manually copy from history

**Error Handling:**
- API errors displayed inline with red card
- Network failures caught and user-friendly messages shown
- Invalid API keys detected during validation

## API Configuration

**OMDB API:**
- Requires free API key from http://www.omdbapi.com/apikey.aspx
- Stored locally via SharedPreferences
- No key included in repository (user must configure)

**Supported Input Formats:**
- IMDB ID: `tt0133093`
- Full URL: `https://www.imdb.com/title/tt0133093/`
- Partial URLs with ID

## Dependencies

**Core Flutter Packages:**
- `http ^1.1.0` - API requests
- `shared_preferences ^2.2.2` - Local storage
- `webview_flutter ^4.4.2` - IMDB browsing
- `url_launcher ^6.2.1` - External URL handling
- `flutter_lints ^5.0.0` - Linting rules

## Platform Support

- **Android**: Configured in `android/`
- **iOS**: Configured in `ios/`
- Target SDK: Dart ^3.9.2
- Material Design 3 (Material 3)

## Working with This Codebase

**Adding New Movie Fields:**
1. Update `Movie` model in `lib/models/movie.dart`
2. Add field to `fromJson()`, `toJson()`, and `toMarkdown()` methods
3. Update UI in relevant pages

**Modifying History Behavior:**
- History limit constant: `MovieHistoryService._maxHistorySize` (default: 50)
- Storage key: `MovieHistoryService._historyKey`
- Deduplication by `imdbID` field

**Changing Theme:**
- Update `MaterialApp` theme in `lib/main.dart`
- Current seed color: `Colors.deepOrange`
- Uses Material 3 design system

**WebView Configuration:**
- JavaScript enabled for IMDB browsing
- No restrictions on navigation
- Loading indicator shown during page transitions
