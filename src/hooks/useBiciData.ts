import { useState, useEffect, useCallback } from 'react';
import { Language, MergedStation, GBFSRoot, StationInfo, StationStatus } from './types';

const ROOT_URL = 'https://gbfs.nextbike.net/maps/gbfs/v2/nextbike_ea/gbfs.json';

export const useBiciData = (lang: Language) => {
  const [stations, setStations] = useState<MergedStation[]>([]);
  const [lastUpdated, setLastUpdated] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      // 1. Fetch Root GBFS
      const rootRes = await fetch(ROOT_URL);
      const rootData: GBFSRoot = await rootRes.json();

      // 2. Find information and status URLs for current language
      const feeds = rootData.data[lang].feeds;
      const infoUrl = feeds.find(f => f.name === 'station_information')?.url;
      const statusUrl = feeds.find(f => f.name === 'station_status')?.url;

      if (!infoUrl || !statusUrl) throw new Error('Feeds not found');

      // 3. Fetch both in parallel
      const [infoRes, statusRes] = await Promise.all([
        fetch(infoUrl),
        fetch(statusUrl)
      ]);

      const infoData = await infoRes.json();
      const statusData = await statusRes.json();

      const infoList: StationInfo[] = infoData.data.stations;
      const statusList: StationStatus[] = statusData.data.stations;

      // 4. Merge data
      const merged: MergedStation[] = infoList.map(info => {
        const status = statusList.find(s => s.station_id === info.station_id);
        
        const manual = status?.vehicle_types_available?.find(v => v.vehicle_type_id === '150')?.count ?? 0;
        const electric = status?.vehicle_types_available?.find(v => v.vehicle_type_id === '143')?.count ?? 0;

        return {
          ...info,
          num_bikes_available: status?.num_bikes_available ?? 0,
          num_manual_available: manual,
          num_electric_available: electric,
          num_docks_available: status?.num_docks_available ?? 0,
          is_renting: status?.is_renting ?? false,
        };
      });

      setStations(merged);
      setLastUpdated(Date.now());
      setLoading(false);
    } catch (err) {
      console.error(err);
      setError('Failed to fetch data');
      setLoading(false);
    }
  }, [lang]);

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 60000); // Reload every minute
    return () => clearInterval(interval);
  }, [fetchData]);

  return { stations, lastUpdated, loading, error, refresh: fetchData };
};
