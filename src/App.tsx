import { useState, useEffect, useMemo } from 'react';
import { useBiciData } from './hooks/useBiciData';
import { MapView } from './components/Map';
import { Sidebar } from './components/Sidebar';
import { Language, MergedStation } from './types';
import { Bike, Map as MapIcon, Globe } from 'lucide-react';
import { calculateDistance } from './utils/geo';

function App() {
  const [lang, setLang] = useState<Language>('es');
  const [userLocation, setUserLocation] = useState<[number, number] | null>(null);
  const [selectedStation, setSelectedStation] = useState<MergedStation | null>(null);
  const { stations, lastUpdated, loading, error } = useBiciData(lang);

  useEffect(() => {
    if (!navigator.geolocation) return;

    const watchId = navigator.geolocation.watchPosition(
      (position) => {
        setUserLocation([position.coords.latitude, position.coords.longitude]);
      },
      (err) => {
        console.error('Geolocation error:', err);
      },
      {
        enableHighAccuracy: true,
        timeout: 5000,
        maximumAge: 0
      }
    );

    return () => navigator.geolocation.clearWatch(watchId);
  }, []);

  const nearestStations = useMemo(() => {
    if (!userLocation || stations.length === 0) return [];

    return stations
      .map(s => ({
        ...s,
        distance: calculateDistance(userLocation[0], userLocation[1], s.lat, s.lon)
      }))
      .filter(s => s.distance !== undefined && s.distance <= 0.5) // Radius of 500m (0.5km)
      .sort((a, b) => (a.distance || 0) - (b.distance || 0));
  }, [stations, userLocation]);

  const handleStationSelect = (station: MergedStation) => {
    setSelectedStation(station);
  };

  const handleSimulatePalma = () => {
    setUserLocation([39.575667, 2.654778]); // Parc de ses Estacions
  };

  return (
    <>
      <header className="header">
        <div className="logo">
          <Bike size={32} />
          <span>BiciPalma Live</span>
        </div>

        <div className="controls">
          <button 
            className="btn-lang" 
            style={{ marginRight: '8px' }}
            onClick={handleSimulatePalma}
          >
            Simulate Palma
          </button>
          <div style={{ display: 'flex', gap: '8px' }}>
            {(['es', 'ca', 'en'] as Language[]).map(l => (
              <button 
                key={l}
                className={`btn-lang ${lang === l ? 'active' : ''}`}
                onClick={() => setLang(l)}
              >
                {l.toUpperCase()}
              </button>
            ))}
          </div>
        </div>
      </header>

      <main className="app-container">
        <Sidebar 
          stations={nearestStations} 
          lang={lang} 
          lastUpdated={lastUpdated} 
          onStationSelect={handleStationSelect}
          waitingForLocation={!userLocation}
        />
        
        <div style={{ flex: 1, position: 'relative' }}>
          {loading && stations.length === 0 ? (
            <div className="glass" style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', padding: '20px', zIndex: 2000 }}>
              Loading BiciPalma data...
            </div>
          ) : (
            <MapView 
              stations={stations} 
              userLocation={userLocation} 
              selectedStation={selectedStation}
            />
          )}
        </div>
      </main>
    </>
  );
}

export default App;
