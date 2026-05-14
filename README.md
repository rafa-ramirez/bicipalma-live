# 🚲 BiciPalma Live

**🌐 Live Demo: [https://rafa-ramirez.github.io/bicipalma-live/](https://rafa-ramirez.github.io/bicipalma-live/)**

A high-performance, real-time mapping application for **BiciPalma**, the public bike-sharing system in Palma de Mallorca. This application provides users with up-to-the-minute information on bike availability, focusing on speed, accuracy, and a premium, state-of-the-art user experience across Web, Desktop, and Mobile.

## ✨ Features

- **Real-Time Data**: Automatically refreshes bike and dock availability every 10 seconds using official GBFS feeds.
- **Cross-Platform**: Built natively with Flutter to run seamlessly on Web, macOS, iOS, and Android without changing code.
- **Native Permissions**: Requests and handles OS-level location permissions gracefully across Android, iOS, and macOS.
- **Smart Mapping**: Interactive map powered by `flutter_map` with custom markers showing the exact breakdown of Manual vs. Electric bikes. Map rotation is locked for an optimal mobile experience.
- **Distance Tracking**: Calculates and displays the exact distance (in meters/km) from your current location to every station in the city, directly on the list and map pop-ups.
- **Mobile-Optimized UX**: Features a responsive `DraggableScrollableSheet` bottom panel on mobile devices for seamless interaction between the map and the stations list.
- **Reliable Location Detection**: Geolocation with intelligent fallback. Clicking the app's title bar or the map's center button instantly centers the map back to your live location.
- **Dynamic Advanced Filtering**: Instantly toggle between "All", "Manual", and "Electric" bikes. Map marker colors and numbers update dynamically based on the applied filter.
- **Multilingual Support**: Fully localized interface in **Spanish**, **Catalan**, and **English**.
- **State-of-the-Art Aesthetics**: Modern "glassmorphism" UI design with frosted transparency, vibrant colors, and smooth 60fps micro-animations powered by `flutter_animate`.

## 🛠️ Technology Stack

- **Frontend**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Mapping**: [flutter_map](https://pub.dev/packages/flutter_map)
- **Data Source**: Official BiciPalma [GBFS (General Bikeshare Feed Specification)](https://gbfs.nextbike.net/maps/gbfs/v2/nextbike_ea/gbfs.json)

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dart SDK (included with Flutter)
- *For Mobile deployment:* Android Studio or Xcode

### Installation

```bash
# Clone the repository
git clone https://github.com/rafa-ramirez/bicipalma-live.git

# Navigate to project directory
cd bicipalma-live

# Install dependencies
flutter pub get
```

### Development

```bash
# Run on web
flutter run -d chrome

# Run on macOS (requires Xcode)
flutter run -d macos

# Run on Android (requires emulator or USB-connected device)
flutter run -d android
```

### Build & Deployment

The project is configured for automated deployment via GitHub Actions.

```bash
# Manual build for web
flutter build web --base-href /bicipalma-live/

# Manual build for Android
flutter build apk
```

The web build output will be in the `build/web` folder, which is automatically deployed to GitHub Pages on every push to the `main` branch.

---

Built with ❤️ for the Palma cycling community.
