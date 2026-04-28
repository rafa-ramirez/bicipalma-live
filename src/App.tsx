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
  const [hasForcedLocation, setHasForcedLocation] = useState(false);
  const [selectedStation, setSelectedStation] = useState<MergedStation | null>(null);
  const [filterType, setFilterType] = useState<'all' | 'manual' | 'electric'>('all');
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isLocating, setIsLocating] = useState(false);
  const [isLangOpen, setIsLangOpen] = useState(false);
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

  /*
  useEffect(() => {
    const timer = setTimeout(() => {
      if (!userLocation && !hasForcedLocation) {
        console.log('Using fallback location: Plaça Espanya');
        setUserLocation([39.5767, 2.6557]);
        setHasForcedLocation(true);
      }
    }, 3000);
    return () => clearTimeout(timer);
  }, [userLocation, hasForcedLocation]);
  */

  useEffect(() => {
    const handleSimulate = () => {
      console.log('Simulation triggered via event');
      setUserLocation([39.5767, 2.6557]);
      setHasForcedLocation(true);
    };
    window.addEventListener('simulate-location', handleSimulate);
    return () => window.removeEventListener('simulate-location', handleSimulate);
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
      .filter(s => s.distance !== undefined && s.distance <= 2.0) // Radius of 2km
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
          <div className="filter-group">
            <button 
              className={`btn-lang ${filterType === 'all' ? 'active' : ''}`} 
              onClick={() => setFilterType('all')}
            >
              {translations[lang].all}
            </button>
            <button 
              className={`btn-lang ${filterType === 'manual' ? 'active' : ''}`} 
              onClick={() => setFilterType('manual')}
            >
              {translations[lang].manual}
            </button>
            <button 
              className={`btn-lang ${filterType === 'electric' ? 'active' : ''}`} 
              onClick={() => setFilterType('electric')}
            >
              {translations[lang].electric}
            </button>
          </div>

          <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
            <button 
              className={`btn-lang ${userLocation && !hasForcedLocation ? 'active' : ''}`}
              onClick={() => {
                if (navigator.geolocation) {
                  setIsLocating(true);
                  navigator.geolocation.getCurrentPosition(
                    (p) => {
                      setUserLocation([p.coords.latitude, p.coords.longitude]);
                      setHasForcedLocation(false);
                      setIsSidebarOpen(true);
                      setIsLocating(false);
                    },
                    (e) => {
                      setIsLocating(false);
                      console.log('Falling back to simulated location');
                      setUserLocation([39.5767, 2.6557]);
                      setHasForcedLocation(true);
                    },
                    { enableHighAccuracy: true, timeout: 10000 }
                  );
                }
              }}
              title="Refresh Location"
            >
              <Navigation size={14} className={isLocating ? 'spin' : ''} />
            </button>

            <div className="lang-dropdown">
              <button 
                className="btn-lang active"
                onClick={() => setIsLangOpen(!isLangOpen)}
                style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
              >
                <Globe size={14} />
                {lang.toUpperCase()}
              </button>
              
              {isLangOpen && (
                <div className="lang-menu">
                  {(['es', 'ca', 'en'] as Language[]).map(l => (
                    <button 
                      key={l}
                      className={`btn-lang ${lang === l ? 'active' : ''}`}
                      onClick={() => {
                        setLang(l);
                        setIsLangOpen(false);
                      }}
                    >
                      {l.toUpperCase()}
                    </button>
                  ))}
                </div>
              )}
            </div>
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
