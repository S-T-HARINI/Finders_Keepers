class CampusLocation {
  const CampusLocation({
    required this.name,
    required this.zone,
    required this.lat,
    required this.lng,
    required this.description,
  });

  final String name;
  final String zone;
  final double lat;
  final double lng;
  final String description;
}

class CampusLocations {
  static const double centerLat = 12.9718;
  static const double centerLng = 77.5946;

  static const List<CampusLocation> all = [
    CampusLocation(
      name: 'Central Library',
      zone: 'Academic Core',
      lat: 12.9716,
      lng: 77.5946,
      description: 'Main reading halls, reference sections, digital catalog kiosks',
    ),
    CampusLocation(
      name: 'Main Cafeteria & Food Court',
      zone: 'Student Center',
      lat: 12.9722,
      lng: 77.5952,
      description: 'Ground floor dining area and outdoor student pavilion',
    ),
    CampusLocation(
      name: 'Seminar Hall 3',
      zone: 'Auditorium Complex',
      lat: 12.9710,
      lng: 77.5938,
      description: 'Conference level, presentation stage, lecture rows',
    ),
    CampusLocation(
      name: 'Sports Complex & Gymnasium',
      zone: 'Recreation Ground',
      lat: 12.9730,
      lng: 77.5960,
      description: 'Indoor courts, track bleachers, equipment desk',
    ),
    CampusLocation(
      name: 'Science & Computing Labs',
      zone: 'Technology Wing',
      lat: 12.9705,
      lng: 77.5950,
      description: 'Hardware lab rooms, robotics arena, 2nd floor workstations',
    ),
    CampusLocation(
      name: 'Student Hostels & Quads',
      zone: 'Residential Zone',
      lat: 12.9735,
      lng: 77.5935,
      description: 'Common rooms, laundry bays, main entrance lobby',
    ),
    CampusLocation(
      name: 'Administration Block',
      zone: 'Admin Plaza',
      lat: 12.9718,
      lng: 77.5940,
      description: 'Dean office, registrar desks, campus security post',
    ),
  ];

  static List<String> get zones => all.map((l) => l.name).toList();
}
