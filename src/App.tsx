import { useState, useEffect, useMemo } from 'react';
const translations = {
  en: { all: 'All', manual: 'Manual', electric: 'Electric' },
  es: { all: 'Todas', manual: 'Manual', electric: 'Eléctrica' },
  ca: { all: 'Totes', manual: 'Manual', electric: 'Elèctrica' },
};
import { useBiciData } from './hooks/useBiciData';
import { MapView } from './components/Map';
import { Sidebar } from './components/Sidebar';
import { Language, MergedStation } from './types';
import { Bike, Map as MapIcon, Globe, Navigation } from 'lucide-react';
import { calculateDistance } from './utils/geo';

function App() {
  const [lang, setLang] = useState<Language>('es');
  const [userLocation, setUserLocation] = useState<[number, number] | null>(null);
  const [selectedStation, setSelectedStation] = useState<MergedStation | null>(null);
  const [filterType, setFilterType] = useState<'all' | 'manual' | 'electric'>('all');
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

    let filtered = stations;
    if (filterType === 'manual') {
      filtered = stations.filter(s => s.num_manual_available > 0);
    } else if (filterType === 'electric') {
      filtered = stations.filter(s => s.num_electric_available > 0);
    }

    return filtered
      .map(s => ({
        ...s,
        distance: calculateDistance(userLocation[0], userLocation[1], s.lat, s.lon)
      }))
      .filter(s => s.distance !== undefined && s.distance <= 0.5) // Radius of 500m (0.5km)
      .sort((a, b) => (a.distance || 0) - (b.distance || 0));
  }, [stations, userLocation, filterType]);

  const handleStationSelect = (station: MergedStation) => {
    setSelectedStation(station);
  };

  return (
    <>
      <header className="header">
        <div className="logo">
          <Bike size={32} />
          <span>BiciPalma</span>
        </div>

        <div className="controls">
          <div style={{ display: 'flex', gap: '4px', marginRight: '16px', background: 'rgba(255,255,255,0.05)', padding: '4px', borderRadius: '10px' }}>
            <button 
              className={`btn-lang ${filterType === 'all' ? 'active' : ''}`} 
              onClick={() => setFilterType('all')}
              style={{ fontSize: '0.75rem' }}
            >
              {translations[lang].all}
            </button>
            <button 
              className={`btn-lang ${filterType === 'manual' ? 'active' : ''}`} 
              onClick={() => setFilterType('manual')}
              style={{ fontSize: '0.75rem' }}
            >
              {translations[lang].manual}
            </button>
            <button 
              className={`btn-lang ${filterType === 'electric' ? 'active' : ''}`} 
              onClick={() => setFilterType('electric')}
              style={{ fontSize: '0.75rem' }}
            >
              {translations[lang].electric}
            </button>
          </div>

          <button 
            className={`btn-lang ${userLocation ? 'active' : ''}`}
            style={{ marginRight: '16px' }}
            onClick={() => {
              if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                  (p) => setUserLocation([p.coords.latitude, p.coords.longitude]),
                  (e) => console.error(e)
                );
              }
            }}
            title="Refresh Location"
          >
            <Navigation size={14} />
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
              filterType={filterType}
            />
          )}
        </div>
      </main>
    </>
  );
}

export default App;
