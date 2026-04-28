# 🚲 BiciPalma Live

A high-performance, real-time mapping application for **BiciPalma**, the public bike-sharing system in Palma de Mallorca. This application provides users with up-to-the-minute information on bike availability, focusing on speed, accuracy, and a premium user experience.

## ✨ Features

- **Real-Time Data**: Automatically refreshes bike and dock availability every minute using official GBFS feeds.
- **Smart Mapping**: Interactive map powered by Leaflet with custom "pill" markers showing the breakdown of Manual vs. Electric bikes at a glance.
- **Location Awareness**: Automatically detects user location to show the nearest stations within a 500m radius.
- **Advanced Filtering**: Quickly toggle between viewing all bikes, or focus specifically on Manual or Electric availability.
- **Multilingual Support**: Fully localized interface in **Spanish**, **Catalan**, and **English**.
- **Performance Optimized**: Built with Vite and TypeScript for instant loading and type-safe data handling.
- **Premium Aesthetics**: Modern "glassmorphism" UI design with responsive layouts for both desktop and mobile.

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
4.  **Responsive Design**: A custom CSS design system using CSS variables and modern layout techniques (Flexbox/Grid) ensures a seamless experience across all device sizes.

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