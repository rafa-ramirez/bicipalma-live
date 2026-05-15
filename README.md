# 🚲 BiciPalma Live

**🌐 Live Demo: [https://rafa-ramirez.github.io/bicipalma-live/](https://rafa-ramirez.github.io/bicipalma-live/)**

A high-performance, real-time mapping application for **BiciPalma**, the public bike-sharing system in Palma de Mallorca. This application provides users with up-to-the-minute information on bike availability, focusing on speed, accuracy, and a premium, state-of-the-art user experience across Web, Desktop, and Mobile.

## ✨ Features

- **Real-Time Data**: Automatically refreshes bike and dock availability every 10 seconds using official GBFS feeds.
- **Cross-Platform**: Built natively with Flutter to run seamlessly on Web, macOS, iOS, and Android.
- **Marker-Centric UI**: A modern, map-first experience where station details emerge directly from markers in stylized bubble popups.
- **Context-Aware Popups**: Marker bubbles feature glassmorphism styling, custom scale animations, and detailed icon badges for a premium feel.
- **Intelligent Z-Index**: Selected stations are dynamically sorted to render on top, ensuring active information is never obscured.
- **Redesigned Mobile Panel**: A responsive `DraggableScrollableSheet` with a new premium header, integrated fullscreen toggle, and smart snap points.
- **Distance Tracking**: Real-time distance calculation from your location to every station, displayed in the list and map bubbles.
- **Multilingual Support**: Fully localized interface in **Spanish**, **Catalan**, and **English**.
- **State-of-the-Art Aesthetics**: Frosted transparency, vibrant harmonious palettes, and 60fps micro-animations.

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
