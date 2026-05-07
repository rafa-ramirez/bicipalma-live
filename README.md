# 🚲 BiciPalma Live

**🌐 Live Demo: [https://rafa-ramirez.github.io/bicipalma-live/](https://rafa-ramirez.github.io/bicipalma-live/)**

A high-performance, real-time mapping application for **BiciPalma**, the public bike-sharing system in Palma de Mallorca. This application provides users with up-to-the-minute information on bike availability, focusing on speed, accuracy, and a premium, state-of-the-art user experience.

## ✨ Features

- **Real-Time Data**: Automatically refreshes bike and dock availability every minute using official GBFS feeds.
- **Smart Mapping**: Interactive map powered by Leaflet with custom "pill" markers showing the breakdown of Manual vs. Electric bikes at a glance.
- **Reliable Location Detection**: Geolocation with intelligent fallback and support for continuous background location updates.
- **Free Map Panning**: Explore the map freely without auto-recentering while navigating.
- **Nearby Stations**: Smart sidebar showing only stations within 500 meters of your location, updated in real-time.
- **Advanced Filtering**: Quickly toggle between viewing all bikes, or focus specifically on Manual or Electric availability.
- **Multilingual Support**: Fully localized interface in **Spanish**, **Catalan**, and **English** with a sleek space-saving selector.
- **Performance Optimized**: Built with Vite and TypeScript for instant loading and type-safe data handling.
- **State-of-the-Art Aesthetics**: Modern "glassmorphism" UI design with a focus on "frosted" transparency, vibrant colors, and smooth micro-animations.

## � Recent Improvements

- **Fixed Geolocation Issues**: Resolved Chrome geolocation timeout problems with optimized timeout settings and intelligent fallback handling.
- **Improved Map Interaction**: Separated map centering from continuous location tracking, allowing users to freely pan and explore without auto-recentering interruptions.
- **Smart Nearby Radius**: Displays only stations within 500 meters (previously 2km) for more contextually relevant results.
- **Enhanced Navigation**: Click the BiciPalma Live logo to reset selection, center the map, and open the sidebar—acting as a convenient "home" button.
- **Better Popup Management**: Popups now close cleanly when deselecting stations for a seamless user experience.

## �📱 Mobile-First Excellence

The application has been meticulously polished for mobile use:
- **Premium Controls**: A "floating pill" design for nearest stations that feels like a native OS control.
- **Compact Navigation**: A space-saving header with a solid dark theme for high contrast and better map visibility.
- **Intuitive Interactions**: Gestures and animations that make exploring bike availability on the go a fluid experience.

## 🛠️ Technology Stack

- **Frontend**: [React 18](https://reactjs.org/)
- **Language**: [TypeScript](https://www.typescriptlang.org/)
- **Build Tool**: [Vite](https://vitejs.dev/)
- **Mapping**: [Leaflet](https://leafletjs.com/) & [React-Leaflet](https://react-leaflet.js.org/)
- **Icons**: [Lucide React](https://lucide.dev/)
- **Data Source**: Official BiciPalma [GBFS (General Bikeshare Feed Specification)](https://gbfs.nextbike.net/maps/gbfs/v2/nextbike_ea/gbfs.json)

## 🏗️ How it was Built

The application follows a modern, modular architecture:

1.  **Data Layer**: A custom React hook (`useBiciData`) handles the complex orchestration of fetching multi-layered GBFS data. It fetches the root discovery file, identifies language-specific feeds, and merges station metadata with real-time status updates in a single, efficient operation.
2.  **Mapping Engine**: Utilizes React-Leaflet for declarative map management. Custom markers are rendered as HTML elements via `L.divIcon`, allowing for dynamic styling and real-time count updates without re-initializing the entire map.
3.  **State Management**: Uses React's `useState` and `useMemo` for high-performance filtering and distance calculations, ensuring the UI remains fluid even with dozens of active markers.
4.  **Responsive Design System**: A bespoke CSS design system using CSS variables, glassmorphism techniques, and a mobile-optimized layout architecture.

## 🚀 Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (Latest LTS recommended)
- [npm](https://www.npmjs.com/)

### Installation

```bash
# Clone the repository
git clone https://github.com/rafa-ramirez/bicipalma-live.git

# Navigate to project directory
cd bicipalma-live

# Install dependencies
npm install
```

### Development

```bash
npm run dev
```

### Build & Deployment

The project is configured for automated deployment via GitHub Actions.

```bash
# Manual build
npm run build
```

The build output will be in the `dist` folder, which is automatically deployed to GitHub Pages on every push to the `main` branch.

---

Built with ❤️ for the Palma cycling community.