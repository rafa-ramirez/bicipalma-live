import { MergedStation, Language } from '../types';
import { Navigation, Clock, X, ChevronLeft, ChevronUp } from 'lucide-react';
import { formatDistance } from '../utils/geo';

interface SidebarProps {
  stations: MergedStation[];
  lang: Language;
  lastUpdated: number | null;
  onStationSelect: (station: MergedStation | null) => void;
  waitingForLocation: boolean;
  selectedId: string | null;
  isOpen: boolean;
  setIsOpen: (open: boolean) => void;
}

const translations = {
  en: { nearest: 'Nearest Stations', bikes: 'Total', manual: 'M', electric: 'E', docks: 'D', updated: 'Updated', waiting: 'Grant location to see nearest stations', empty: 'No stations within 500m' },
  es: { nearest: 'Estaciones Cercanas', bikes: 'Total', manual: 'M', electric: 'E', docks: 'A', updated: 'Actualizado', waiting: 'Permite el acceso a la ubicación', empty: 'No hay estaciones a menos de 500m' },
  ca: { nearest: 'Estacions Properes', bikes: 'Total', manual: 'M', electric: 'E', docks: 'A', updated: 'Actualitzat', waiting: 'Permet l\'accés a la ubicació', empty: 'No hi ha estacions a menys de 500m' },
};

console.log('Sidebar.tsx loaded');

export const Sidebar = ({ 
  stations, 
  lang, 
  lastUpdated, 
  onStationSelect, 
  waitingForLocation, 
  selectedId, 
  isOpen, 
  setIsOpen 
}: SidebarProps) => {
  const t = translations[lang];
  console.log('Sidebar render:', { isOpen, stationsCount: stations.length, waitingForLocation });

  return (
    <div className={`sidebar glass ${isOpen ? 'open' : 'closed'}`}>
      <div className="drawer-handle" />
      <div 
        className="sidebar-header"
        style={{ 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'space-between',
          color: 'var(--primary)',
          cursor: 'pointer',
          padding: isOpen ? '8px' : '0 4px',
          borderRadius: '12px',
          transition: 'all 0.2s',
          marginBottom: isOpen ? '16px' : '0',
          marginTop: isOpen ? '0' : '0'
        }}
        onClick={(e) => {
          e.stopPropagation();
          setIsOpen(!isOpen);
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Navigation size={18} className={!isOpen ? 'pulse' : ''} />
          <h2 style={{ fontSize: '1rem', fontWeight: 700, letterSpacing: '-0.01em' }}>{t.nearest}</h2>
        </div>
        <div className="toggle-icon">
          {isOpen ? (
            <X size={20} />
          ) : (
            <ChevronUp size={20} />
          )}
        </div>
      </div>

      {isOpen && (
        <>
          {lastUpdated && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.7rem', color: 'var(--text-muted)', marginBottom: '4px' }}>
              <Clock size={10} />
              {t.updated}: {new Date(lastUpdated).toLocaleTimeString()}
            </div>
          )}

          {waitingForLocation ? (
            <div style={{ textAlign: 'center', padding: '20px', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
              {t.waiting}
              <div 
                style={{ marginTop: '12px', color: 'var(--accent)', cursor: 'pointer', textDecoration: 'underline' }}
                onClick={(e) => {
                  e.stopPropagation();
                  window.dispatchEvent(new CustomEvent('simulate-location'));
                }}
              >
                (Simulate Palma Location)
              </div>
            </div>
          ) : stations.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '20px', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
              {t.empty}
            </div>
          ) : (
            stations.map((station) => (
              <div 
                key={station.station_id} 
                className={`station-card ${selectedId === station.station_id ? 'selected' : ''}`}
                onClick={(e) => {
                  e.stopPropagation();
                  onStationSelect(station);
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '8px' }}>
                  <div className="station-name">
                    {station.name}
                  </div>
                  {station.distance !== undefined && (
                    <span className="distance-tag">
                      {formatDistance(station.distance)}
                    </span>
                  )}
                </div>
                
                <div className="availability-grid" style={{ gridTemplateColumns: '1fr 1fr 1fr' }}>
                  <div className="avail-item">
                    <span className="avail-label">{t.manual}</span>
                    <span className="avail-value" style={{ 
                      color: station.num_manual_available > 0 ? '#10b981' : '#cbd5e1' 
                    }}>
                      {station.num_manual_available}
                    </span>
                  </div>
                  <div className="avail-item">
                    <span className="avail-label">{t.electric}</span>
                    <span className="avail-value" style={{ 
                      color: station.num_electric_available > 0 ? '#38bdf8' : '#cbd5e1' 
                    }}>
                      {station.num_electric_available}
                    </span>
                  </div>
                  <div className="avail-item">
                    <span className="avail-label">{t.docks}</span>
                    <span className="avail-value docks">{station.num_docks_available}</span>
                  </div>
                </div>
              </div>
            ))
          )}
        </>
      )}
    </div>
  );
};
