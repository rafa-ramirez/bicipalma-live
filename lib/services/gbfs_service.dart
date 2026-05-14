import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bicipalma_live/models/station.dart';

class GbfsService {
  final String gbfsRootUrl =
      'https://gbfs.nextbike.net/maps/gbfs/v2/nextbike_ea/gbfs.json';

  Future<Map<String, String>> _fetchFeedUrls(Language language) async {
    final response = await http.get(Uri.parse(gbfsRootUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final feeds = data['data'][language.code]['feeds'] as List;
      String stationInfoUrl = '';
      String stationStatusUrl = '';

      for (var feed in feeds) {
        if (feed['name'] == 'station_information') {
          stationInfoUrl = feed['url'];
        } else if (feed['name'] == 'station_status') {
          stationStatusUrl = feed['url'];
        }
      }

      if (stationInfoUrl.isEmpty || stationStatusUrl.isEmpty) {
        throw Exception('Station feeds missing for ${language.code}');
      }

      return {'info': stationInfoUrl, 'status': stationStatusUrl};
    } else {
      throw Exception('Failed to load GBFS feed URLs');
    }
  }

  Future<List<Station>> fetchStations(Language language) async {
    final urls = await _fetchFeedUrls(language);
    final infoResponse = await http.get(Uri.parse(urls['info']!));
    final statusResponse = await http.get(Uri.parse(urls['status']!));

    if (infoResponse.statusCode == 200 && statusResponse.statusCode == 200) {
      final infoData = json.decode(infoResponse.body);
      final statusData = json.decode(statusResponse.body);

      final stationsInfo = infoData['data']['stations'] as List;
      final stationsStatus = statusData['data']['stations'] as List;

      final Map<String, dynamic> statusMap = {
        for (var item in stationsStatus) item['station_id']: item,
      };

      return stationsInfo.map<Station>((info) {
        final status = statusMap[info['station_id']];
        if (status == null) {
          return Station(
            id: info['station_id'],
            name: info['name'],
            lat: info['lat'],
            lon: info['lon'],
            capacity: info['capacity'] ?? 0,
            numBikesAvailable: 0,
            numManualAvailable: 0,
            numElectricAvailable: 0,
            numDocksAvailable: 0,
            isRenting: false,
          );
        }

        int numManualAvailable = 0;
        int numElectricAvailable = 0;

        if (status['vehicle_types_available'] != null) {
          for (var vt in status['vehicle_types_available']) {
            if (vt['vehicle_type_id'] == '150') {
              numManualAvailable = vt['count'];
            } else if (vt['vehicle_type_id'] == '143') {
              numElectricAvailable = vt['count'];
            }
          }
        }

        return Station(
          id: info['station_id'],
          name: info['name'],
          lat: info['lat'],
          lon: info['lon'],
          capacity: info['capacity'] ?? 0,
          numBikesAvailable: status['num_bikes_available'] ?? 0,
          numManualAvailable: numManualAvailable,
          numElectricAvailable: numElectricAvailable,
          numDocksAvailable: status['num_docks_available'] ?? 0,
          isRenting: status['is_renting'] == 1,
        );
      }).toList();
    } else {
      throw Exception('Failed to load station data');
    }
  }
}
