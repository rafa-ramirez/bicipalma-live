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
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUserLocation([position.coords.latitude, position.coords.longitude]);
        },
        (err) => console.error('Geolocation error:', err)
      );
    }
  }, []);

  const nearestStations = useMemo(() => {
    if (!userLocation || stations.length === 0) return [];

    return stations
      .map(s => ({
        ...s,
        distance: calculateDistance(userLocation[0], userLocation[1], s.lat, s.lon)
      }))
      .sort((a, b) => (a.distance || 0) - (b.distance || 0))
      .slice(0, 10);
  }, [stations, userLocation]);

  const handleStationSelect = (station: MergedStation) => {
    setSelectedStation(station);
  };

  return (
    <>
      <header className="header">
        <div className="logo">
          <Bike size={32} />
          <span>BiciPalma Live</span>
        </div>

        <div className="controls">
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
