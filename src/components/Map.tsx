import { useEffect, useRef } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import { MergedStation } from '../types';
import { Bike } from 'lucide-react';

interface MapProps {
  stations: MergedStation[];
  userLocation: [number, number] | null;
  selectedStation: MergedStation | null;
}

const createBikeIcon = (bikes: number) => {
  const color = bikes === 0 ? '#ef4444' : bikes < 3 ? '#f59e0b' : '#10b981';
  const html = `
    <div style="
      background: white;
      border: 3px solid ${color};
      border-radius: 50%;
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: ${color};
      font-weight: bold;
      font-size: 12px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    ">
      ${bikes}
    </div>
  `;

  return L.divIcon({
    html,
    className: 'custom-bike-icon',
    iconSize: [32, 32],
    iconAnchor: [16, 16],
  });
};

// Component to handle map centering and popup
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

export const MapView = ({ stations, userLocation, selectedStation }: MapProps) => {
  const center: [number, number] = [39.5696, 2.6502]; // Palma de Mallorca center
  const markerRefs = useRef<Map<string, L.Marker>>(new Map());

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
      
      {stations.map((station) => (
        <Marker 
          key={station.station_id} 
          position={[station.lat, station.lon]}
          icon={createBikeIcon(station.num_bikes_available)}
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
      ))}

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
