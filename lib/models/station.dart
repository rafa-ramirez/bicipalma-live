enum Language { es, ca, en }

extension LanguageCode on Language {
  String get code => name;
}

class Station {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final int capacity;
  final int numBikesAvailable;
  final int numManualAvailable;
  final int numElectricAvailable;
  final int numDocksAvailable;
  final bool isRenting;
  final double? distance;

  Station({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.capacity,
    required this.numBikesAvailable,
    required this.numManualAvailable,
    required this.numElectricAvailable,
    required this.numDocksAvailable,
    required this.isRenting,
    this.distance,
  });

  Station copyWith({double? distance}) {
    return Station(
      id: id,
      name: name,
      lat: lat,
      lon: lon,
      capacity: capacity,
      numBikesAvailable: numBikesAvailable,
      numManualAvailable: numManualAvailable,
      numElectricAvailable: numElectricAvailable,
      numDocksAvailable: numDocksAvailable,
      isRenting: isRenting,
      distance: distance ?? this.distance,
    );
  }
}
