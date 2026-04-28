import { MergedStation, Language } from '../types';
import { Navigation, Bike, MapPin, Clock } from 'lucide-react';
import { formatDistance } from '../utils/geo';

interface SidebarProps {
  stations: MergedStation[];
  lang: Language;
  lastUpdated: number | null;
  onStationSelect: (station: MergedStation) => void;
  waitingForLocation: boolean;
}

const translations = {
  en: { nearest: 'Nearest Stations', bikes: 'Total', manual: 'M', electric: 'E', docks: 'D', updated: 'Updated', waiting: 'Grant location to see nearest stations', empty: 'No stations within 500m' },
  es: { nearest: 'Estaciones Cercanas', bikes: 'Total', manual: 'M', electric: 'E', docks: 'A', updated: 'Actualizado', waiting: 'Permite el acceso a la ubicación', empty: 'No hay estaciones a menos de 500m' },
  ca: { nearest: 'Estacions Properes', bikes: 'Total', manual: 'M', electric: 'E', docks: 'A', updated: 'Actualitzat', waiting: 'Permet l\'accés a la ubicació', empty: 'No hi ha estacions a menys de 500m' },
};

export const Sidebar = ({ stations, lang, lastUpdated, onStationSelect, waitingForLocation }: SidebarProps) => {
  const t = translations[lang];

  return (
    <div className="sidebar glass">
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--primary)' }}>
        <Navigation size={18} />
        <h2 style={{ fontSize: '1.1rem', fontWeight: 700 }}>{t.nearest}</h2>
      </div>

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
            
            <div className="availability-grid" style={{ gridTemplateColumns: '1fr 1fr 1fr' }}>
              <div className="avail-item">
                <span className="avail-label">{t.manual}</span>
                <span className="avail-value" style={{ color: station.num_manual_available > 0 ? 'var(--primary)' : 'var(--text-muted)' }}>
                  {station.num_manual_available}
                </span>
              </div>
              <div className="avail-item">
                <span className="avail-label">{t.electric}</span>
                <span className="avail-value" style={{ color: station.num_electric_available > 0 ? 'var(--accent)' : 'var(--text-muted)' }}>
                  {station.num_electric_available}
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

    </div>
  );
};
