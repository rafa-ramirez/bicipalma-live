export interface StationInfo {
  station_id: string;
  name: string;
  short_name: string;
  lat: number;
  lon: number;
  capacity: number;
}

export interface StationStatus {
  station_id: string;
  num_bikes_available: number;
  vehicle_types_available?: Array<{
    vehicle_type_id: string;
    count: number;
  }>;
  num_docks_available: number;
  is_installed: boolean;
  is_renting: boolean;
  is_returning: boolean;
  last_reported: number;
}

export interface MergedStation extends StationInfo {
  num_bikes_available: number;
  num_manual_available: number;
  num_electric_available: number;
  num_docks_available: number;
  is_renting: boolean;
  distance?: number;
}

export type Language = 'en' | 'es' | 'ca';

export interface GBFSFeed {
  name: string;
  url: string;
}

export interface GBFSRoot {
  data: {
    [key in Language]: {
      feeds: GBFSFeed[];
    };
  };
}
