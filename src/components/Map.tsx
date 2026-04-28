import { useEffect, useRef } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import { MergedStation } from '../types';

interface MapProps {
  stations: MergedStation[];
  userLocation: [number, number] | null;
  selectedStation: MergedStation | null;
  onStationSelect: (station: MergedStation | null) => void;
  filterType: 'all' | 'manual' | 'electric';
}

const createBikeIcon = (manual: number, electric: number, filterType: string, isSelected: boolean) => {
  const total = manual + electric;
  const color = total === 0 ? '#ef4444' : total < 3 ? '#f59e0b' : '#10b981';
  
  const showManual = filterType === 'all' || filterType === 'manual';
  const showElectric = filterType === 'all' || filterType === 'electric';
  const showBoth = showManual && showElectric;

  const html = `
    <div style="
      background: white;
      border: 2px solid ${color};
      border-radius: 20px;
      padding: 2px 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
      white-space: nowrap;
      min-width: 30px;
    ">
      ${showManual ? `<span style="color: #10b981; font-weight: 800; font-size: 11px;">M ${manual}</span>` : ''}
      ${showBoth ? `<span style="color: #e2e8f0; width: 1px; height: 12px; background: #e2e8f0;"></span>` : ''}
      ${showElectric ? `<span style="color: #38bdf8; font-weight: 800; font-size: 11px;">E ${electric}</span>` : ''}
    </div>
  `;

  return L.divIcon({
    html,
    className: 'custom-bike-icon-pill',
    iconSize: [showBoth ? 70 : 40, 24],
    iconAnchor: [showBoth ? 35 : 20, 12],
  });
};

const MapController = ({ coords, selectedStation, markerRefs }: { 
  coords: [number, number] | null, 
  selectedStation: MergedStation | null,
  markerRefs: React.MutableRefObject<Map<string, L.Marker>>
}) => {
  const map = useMap();
  
  useEffect(() => {
    if (coords) {
      map.setView(coords, 15);
    }
  }, [coords, map]);

  useEffect(() => {
    if (selectedStation) {
      map.setView([selectedStation.lat, selectedStation.lon], 16);
      const marker = markerRefs.current.get(selectedStation.station_id);
      if (marker) {
        marker.openPopup();
      }
    }
  }, [selectedStation, map, markerRefs]);

  return null;
};

export const MapView = ({ stations, userLocation, selectedStation, onStationSelect, filterType }: MapProps) => {
  const center: [number, number] = [39.5696, 2.6502];
  const markerRefs = useRef<Map<string, L.Marker>>(new Map());

  const filteredStations = stations.filter(s => {
    if (filterType === 'manual') return s.num_manual_available > 0;
    if (filterType === 'electric') return s.num_electric_available > 0;
    return true;
  });

  const MapEvents = () => {
    useMapEvents({
      click: () => onStationSelect(null)
    });
    return null;
  };

  return (
    <MapContainer 
      center={center} 
      zoom={14} 
      scrollWheelZoom={true} 
      style={{ height: '100%', width: '100%' }}
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      
      <MapEvents />

      {filteredStations.map((station) => {
        const isSelected = selectedStation?.station_id === station.station_id;
        return (
          <Marker 
            key={station.station_id} 
            position={[station.lat, station.lon]}
            icon={createBikeIcon(
              station.num_manual_available, 
              station.num_electric_available, 
              filterType,
              isSelected
            )}
            eventHandlers={{
              click: () => onStationSelect(station),
              add: (e) => {
                if (isSelected) {
                  (e.target as L.Marker).openPopup();
                }
              }
            }}
            ref={(ref) => {
              if (ref) {
                markerRefs.current.set(station.station_id, ref);
              } else {
                markerRefs.current.delete(station.station_id);
              }
            }}
          >
            <Popup>
              <div style={{ color: '#0f172a', minWidth: '150px' }}>
                <h3 style={{ margin: '0 0 8px 0', fontSize: '0.9rem', fontWeight: 600 }}>{station.name}</h3>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '4px' }}>
                  <div style={{ textAlign: 'center', padding: '6px 2px', background: '#f1f5f9', borderRadius: '6px' }}>
                    <div style={{ fontWeight: 'bold', fontSize: '1rem', color: '#10b981' }}>{station.num_manual_available}</div>
                    <div style={{ fontSize: '0.6rem', color: '#64748b', textTransform: 'uppercase' }}>Manual</div>
                  </div>
                  <div style={{ textAlign: 'center', padding: '6px 2px', background: '#f1f5f9', borderRadius: '6px' }}>
                    <div style={{ fontWeight: 'bold', fontSize: '1rem', color: '#38bdf8' }}>{station.num_electric_available}</div>
                    <div style={{ fontSize: '0.6rem', color: '#64748b', textTransform: 'uppercase' }}>Electric</div>
                  </div>
                  <div style={{ textAlign: 'center', padding: '6px 2px', background: '#f1f5f9', borderRadius: '6px' }}>
                    <div style={{ fontWeight: 'bold', fontSize: '1rem' }}>{station.num_docks_available}</div>
                    <div style={{ fontSize: '0.6rem', color: '#64748b', textTransform: 'uppercase' }}>Docks</div>
                  </div>
                </div>
              </div>
            </Popup>
          </Marker>
        );
      })}

      {userLocation && (
        <Marker 
          position={userLocation}
          icon={L.divIcon({
            html: '<div style="width: 20px; height: 20px; background: #38bdf8; border: 3px solid white; border-radius: 50%; box-shadow: 0 0 10px rgba(56, 189, 248, 0.5);"></div>',
            className: 'user-location-marker',
            iconSize: [20, 20],
            iconAnchor: [10, 10],
          })}
        />
      )}

      <MapController 
        coords={userLocation} 
        selectedStation={selectedStation} 
        markerRefs={markerRefs} 
      />
    </MapContainer>
  );
};
