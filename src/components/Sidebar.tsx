import { MergedStation, Language } from '../types';
import { Navigation, Bike, MapPin, Clock } from 'lucide-react';
import { formatDistance } from '../utils/geo';

interface SidebarProps {
  stations: MergedStation[];
  lang: Language;
  lastUpdated: number | null;
  onStationSelect: (station: MergedStation) => void;
}

const translations = {
  en: { nearest: 'Nearest Stations', bikes: 'Bikes', docks: 'Docks', updated: 'Updated' },
  es: { nearest: 'Estaciones Cercanas', bikes: 'Bicis', docks: 'Anclajes', updated: 'Actualizado' },
  ca: { nearest: 'Estacions Properes', bikes: 'Bicis', docks: 'Ancoratges', updated: 'Actualitzat' },
};

export const Sidebar = ({ stations, lang, lastUpdated, onStationSelect }: SidebarProps) => {
  const t = translations[lang];

  return (
    <div className="sidebar glass">
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)' }}>
        <Navigation size={18} />
        <h2 style={{ fontSize: '1.1rem', fontWeight: 700 }}>{t.nearest}</h2>
      </div>

      {stations.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '20px', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
          Grant location access to see nearest stations
        </div>
      ) : (
        stations.map((station) => (
          <div 
            key={station.station_id} 
            className="station-card"
            onClick={() => onStationSelect(station)}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '8px' }}>
              <div style={{ fontWeight: 600, fontSize: '0.85rem', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {station.name}
              </div>
              {station.distance !== undefined && (
                <span className="distance-tag" style={{ flexShrink: 0 }}>{formatDistance(station.distance)}</span>
              )}
            </div>
            
            <div className="availability-grid">
              <div className="avail-item">
                <span className="avail-label">{t.bikes}</span>
                <span className="avail-value" style={{ color: station.num_bikes_available > 0 ? 'var(--primary)' : '#ef4444' }}>
                  {station.num_bikes_available}
                </span>
              </div>
              <div className="avail-item">
                <span className="avail-label">{t.docks}</span>
                <span className="avail-value">{station.num_docks_available}</span>
              </div>
            </div>
          </div>
        ))
      )}

      {lastUpdated && (
        <div style={{ marginTop: 'auto', display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
          <Clock size={12} />
          {t.updated}: {new Date(lastUpdated).toLocaleTimeString()}
        </div>
      )}
    </div>
  );
};
