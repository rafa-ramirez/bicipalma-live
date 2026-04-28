import { MergedStation, Language } from '../types';
import { Navigation, Bike, MapPin, Clock, X, ChevronLeft, ChevronRight } from 'lucide-react';
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

export const Sidebar = ({ stations, lang, lastUpdated, onStationSelect, waitingForLocation, selectedId, isOpen, setIsOpen }: SidebarProps) => {
  const t = translations[lang];

  return (
    <div className={`sidebar glass ${isOpen ? 'open' : 'closed'}`}>
      <div 
        style={{ 
          display: 'flex', 
          alignItems: 'center', 
          justify-content: 'space-between',
          color: 'var(--primary)',
          cursor: 'pointer',
          paddingBottom: isOpen ? '12px' : '0'
        }}
        onClick={() => setIsOpen(!isOpen)}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Navigation size={18} />
          <h2 style={{ fontSize: '1.1rem', fontWeight: 700 }}>{t.nearest}</h2>
        </div>
        <div className="mobile-only">
          {isOpen ? <X size={20} /> : <ChevronLeft size={20} />}
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
            onClick={() => onStationSelect(station)}
            style={{ 
              borderColor: selectedId === station.station_id ? 'white' : 'var(--glass-border)',
              background: selectedId === station.station_id ? 'rgba(255, 255, 255, 0.95)' : 'rgba(30, 41, 59, 0.5)',
              boxShadow: selectedId === station.station_id ? '0 4px 20px rgba(0, 0, 0, 0.3)' : 'none',
              transform: selectedId === station.station_id ? 'translateX(-8px)' : 'none'
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '8px' }}>
              <div style={{ 
                fontWeight: 800, 
                fontSize: '0.9rem', 
                color: selectedId === station.station_id ? '#0f172a' : 'white',
                overflow: 'hidden', 
                textOverflow: 'ellipsis', 
                whiteSpace: 'nowrap' 
              }}>
                {station.name}
              </div>
              {station.distance !== undefined && (
                <span className="distance-tag" style={{ 
                  flexShrink: 0,
                  background: selectedId === station.station_id ? '#0f172a' : 'rgba(56, 189, 248, 0.2)',
                  color: selectedId === station.station_id ? 'white' : 'var(--accent)'
                }}>
                  {formatDistance(station.distance)}
                </span>
              )}
            </div>
            
            <div className="availability-grid" style={{ gridTemplateColumns: '1fr 1fr 1fr' }}>
              <div className="avail-item" style={{ background: selectedId === station.station_id ? 'rgba(0,0,0,0.05)' : 'rgba(15, 23, 42, 0.3)' }}>
                <span className="avail-label" style={{ color: selectedId === station.station_id ? '#64748b' : 'var(--text-muted)' }}>{t.manual}</span>
                <span className="avail-value" style={{ 
                  color: station.num_manual_available > 0 ? '#10b981' : '#cbd5e1' 
                }}>
                  {station.num_manual_available}
                </span>
              </div>
              <div className="avail-item" style={{ background: selectedId === station.station_id ? 'rgba(0,0,0,0.05)' : 'rgba(15, 23, 42, 0.3)' }}>
                <span className="avail-label" style={{ color: selectedId === station.station_id ? '#64748b' : 'var(--text-muted)' }}>{t.electric}</span>
                <span className="avail-value" style={{ 
                  color: station.num_electric_available > 0 ? '#38bdf8' : '#cbd5e1' 
                }}>
                  {station.num_electric_available}
                </span>
              </div>
              <div className="avail-item" style={{ background: selectedId === station.station_id ? 'rgba(0,0,0,0.05)' : 'rgba(15, 23, 42, 0.3)' }}>
                <span className="avail-label" style={{ color: selectedId === station.station_id ? '#64748b' : 'var(--text-muted)' }}>{t.docks}</span>
                <span className="avail-value" style={{ color: selectedId === station.station_id ? '#0f172a' : 'white' }}>{station.num_docks_available}</span>
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
