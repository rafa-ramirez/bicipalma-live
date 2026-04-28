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
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isLocating, setIsLocating] = useState(false);
  const { stations, lastUpdated, loading, error } = useBiciData(lang);

  useEffect(() => {
    if (!navigator.geolocation) return;

    const watchId = navigator.geolocation.watchPosition(
      (position) => {
        console.log('Location updated:', position.coords.latitude, position.coords.longitude);
        setUserLocation([position.coords.latitude, position.coords.longitude]);
      },
      (err) => {
        console.error('Geolocation error:', err);
        // If high accuracy failed, try again without it
        if (err.code === err.TIMEOUT) {
          navigator.geolocation.getCurrentPosition(
            (p) => setUserLocation([p.coords.latitude, p.coords.longitude]),
            (e) => console.error('Fallback geolocation failed:', e),
            { enableHighAccuracy: false, timeout: 10000 }
          );
        }
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 10000
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

  const handleStationSelect = (station: MergedStation | null) => {
    setSelectedStation(station);
    if (station && window.innerWidth < 768) {
      setIsSidebarOpen(false);
    }
  };

  return (
    <>
      <header className="header">
        <div className="logo">
          <Bike size={32} />
          <span>BiciPalma Live</span>
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
                setIsLocating(true);
                navigator.geolocation.getCurrentPosition(
                  (p) => {
                    setUserLocation([p.coords.latitude, p.coords.longitude]);
                    setIsLocating(false);
                  },
                  (e) => {
                    console.error('Manual refresh error:', e);
                    setIsLocating(false);
                    alert('Could not get location. Please ensure GPS is enabled and permissions are granted.');
                  },
                  { enableHighAccuracy: true, timeout: 10000 }
                );
              }
            }}
            title="Refresh Location"
          >
            <Navigation size={14} className={isLocating ? 'spin' : ''} />
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
          selectedId={selectedStation?.station_id || null}
          isOpen={isSidebarOpen}
          setIsOpen={setIsSidebarOpen}
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
              onStationSelect={handleStationSelect}
              filterType={filterType}
            />
          )}
        </div>
      </main>
    </>
  );
}

export default App;
