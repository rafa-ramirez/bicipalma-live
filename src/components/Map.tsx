import { useEffect } from 'react';
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
const MapController = ({ coords, selectedStation }: { coords: [number, number] | null, selectedStation: MergedStation | null }) => {
  const map = useMap();
  
  useEffect(() => {
    if (coords) {
      map.setView(coords, 15);
    }
  }, [coords, map]);

  useEffect(() => {
    if (selectedStation) {
      map.setView([selectedStation.lat, selectedStation.lon], 16);
      // We'll let the Marker's own ref handle opening the popup or just center it.
      // Leaflet doesn't easily allow opening popups by ID without refs, 
      // but centering is a good start.
    }
  }, [selectedStation, map]);

  return null;
};

export const MapView = ({ stations, userLocation, selectedStation }: MapProps) => {
  const center: [number, number] = [39.5696, 2.6502]; // Palma de Mallorca center

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
          eventHandlers={{
            add: (e) => {
              if (selectedStation?.station_id === station.station_id) {
                e.target.openPopup();
              }
            }
          }}
        >
          <Popup>
            <div style={{ color: '#0f172a' }}>
              <h3 style={{ margin: '0 0 8px 0', fontSize: '1rem' }}>{station.name}</h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                <div style={{ textAlign: 'center', padding: '4px', background: '#f1f5f9', borderRadius: '4px' }}>
                  <div style={{ fontWeight: 'bold' }}>{station.num_bikes_available}</div>
                  <div style={{ fontSize: '0.7rem' }}>Bikes</div>
                </div>
                <div style={{ textAlign: 'center', padding: '4px', background: '#f1f5f9', borderRadius: '4px' }}>
                  <div style={{ fontWeight: 'bold' }}>{station.num_docks_available}</div>
                  <div style={{ fontSize: '0.7rem' }}>Docks</div>
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

      <MapController coords={userLocation} selectedStation={selectedStation} />
    </MapContainer>
  );
};
