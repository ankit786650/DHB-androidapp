import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Facility {
  final String name;
  final String type;
  final String address;
  final String phone;
  final List<String> tags;
  final double lat;
  final double lng;

  Facility({
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.tags,
    required this.lat,
    required this.lng,
  });
}

class NearbyFacilitiesScreen extends StatefulWidget {
  const NearbyFacilitiesScreen({super.key});

  @override
  State<NearbyFacilitiesScreen> createState() => _NearbyFacilitiesScreenState();
}

class _NearbyFacilitiesScreenState extends State<NearbyFacilitiesScreen> {
  Position? _currentPosition;
  MapController? _mapController;
  bool _loading = true;
  String _error = '';
  final List<Marker> _markers = [];

  final List<Facility> _facilities = [
    Facility(
      name: "City General Hospital",
      type: "Government Hospital",
      address: "123 Main Street, Bangalore",
      phone: "+91 80 1234 5678",
      tags: ["Emergency Care", "Surgery", "Pediatrics"],
      lat: 12.9716,
      lng: 77.5946,
    ),
    Facility(
      name: "Community Health Center",
      type: "Health Centers",
      address: "456 Health Avenue, Bangalore",
      phone: "+91 80 2345 6789",
      tags: ["Primary Care", "Vaccination", "Maternal Health"],
      lat: 12.9810,
      lng: 77.6000,
    ),
    Facility(
      name: "MedPlus Pharmacy",
      type: "Pharmacy",
      address: "789 Medicine Road, Bangalore",
      phone: "+91 80 3456 7890",
      tags: ["Prescription Drugs", "Over-the-counter Medicines", "Health Supplies"],
      lat: 12.9700,
      lng: 77.6040,
    ),
    Facility(
      name: "Dr. Sharma's Clinic",
      type: "Clinic",
      address: "321 Doctor Lane, Bangalore",
      phone: "",
      tags: [],
      lat: 12.9684,
      lng: 77.5800,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _error = 'Location services are disabled.';
        _loading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permissions are denied';
          _loading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _error = 'Location permissions are permanently denied.';
        _loading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _loading = false;
      });
      // Move map to new position if map is already created
      if (_mapController != null) {
        _mapController!.move(
          LatLng(position.latitude, position.longitude),
 _mapController!.camera.zoom,
        );
        _addMarkers();
      }
    } catch (e) {
      setState(() {
        _error = 'Error retrieving current location.';
        _loading = false;
      });
    }
  }

  List<Facility> _facilitiesWithinKM(double km) {
    if (_currentPosition == null) return [];
    return _facilities.where((f) {
      final double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        f.lat,
        f.lng,
      );
      return distance <= km * 1000;
    }).toList();
  }

  void _addMarkers() {
    if (_currentPosition == null) return;
    
    setState(() {
      _markers.clear();
      
      // Add user location marker
      _markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 40,
        ),
      )
      );

      // Add facility markers
      final facilitiesNearby = _facilitiesWithinKM(11);
      for (var f in facilitiesNearby) {
        Color markerColor;
        if (f.type.toLowerCase().contains("hospital")) {
          markerColor = Colors.red;
        } else if (f.type.toLowerCase().contains("pharmacy")) {
          markerColor = Colors.purple;
        } else if (f.type.toLowerCase().contains("clinic")) {
          markerColor = Colors.green;
        } else {
          markerColor = Colors.orange;
        }

        _markers.add(
          Marker(
            point: LatLng(f.lat, f.lng),
            child: Icon(
              Icons.location_on,
              color: markerColor,
              size: 40,
          ),
        )
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const double searchRadiusKm = 11;
    final facilitiesNearby = _facilitiesWithinKM(searchRadiusKm);
    final hospitals = facilitiesNearby.where((f) =>
      f.type.toLowerCase().contains("hospital") ||
      f.type.toLowerCase().contains("health")
    ).toList();
    final clinicsPharmacies = facilitiesNearby.where((f) =>
      f.type.toLowerCase().contains("clinic") ||
      f.type.toLowerCase().contains("pharmacy")
    ).toList();

    final isWideScreen = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Facilities"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              await _determinePosition();
              // Center map if possible
              if (_mapController != null && _currentPosition != null) {
                _mapController!.move(
                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
 _mapController!.camera.zoom,
                );
                _addMarkers();
              }
            },
            tooltip: "My Location",
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _currentPosition == null
                  ? const Center(child: Text("Getting your location..."))
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.my_location),
                                  onPressed: () async {
                                    await _determinePosition();
                                    if (_mapController != null && _currentPosition != null) {
                                      _mapController!.move(
                                        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
 _mapController!.camera.zoom,
                                      );
                                      _addMarkers();
                                    }
                                  },
                                  tooltip: "My Location",
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: "All",
                                  items: const [
                                    DropdownMenuItem(value: "All", child: Text("All Facility Types")),
                                    DropdownMenuItem(value: "Hospital", child: Text("Hospital")),
                                    DropdownMenuItem(value: "Clinic", child: Text("Clinic")),
                                    DropdownMenuItem(value: "Pharmacy", child: Text("Pharmacy")),
                                  ],
                                  onChanged: (v) {},
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _addMarkers();
                                    });
                                  },
                                  icon: const Icon(Icons.location_searching),
                                  label: Text("Find Nearby (${searchRadiusKm.toInt()}km)"),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: isWideScreen
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 400,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(18),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey.withOpacity(0.2),
                                                    spreadRadius: 2,
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(18),
                                                child: FlutterMap(
                                                  mapController: _mapController,
                                                  options: MapOptions(
                                                    initialCenter: LatLng(
 _currentPosition!.latitude,
 _currentPosition!.longitude,
                                                    ),
                                                    initialZoom: 13.0,

                                                    minZoom: 13.0,
                                                  ),
                                                  children: [
                                                    TileLayer(
                                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                      userAgentPackageName: 'com.example.app',
                                                    ),
                                                    MarkerLayer(markers: _markers),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Text(
                                                '© OpenStreetMap contributors',
                                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: _buildFacilitiesList(hospitals, clinicsPharmacies, facilitiesNearby),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Container(
                                        height: 220,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.2),
                                              spreadRadius: 2,
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: FlutterMap(
                                            mapController: _mapController,
                                            options: MapOptions(
                                              initialCenter: LatLng(
 _currentPosition!.latitude,
 _currentPosition!.longitude,
                                              ),
                                              initialZoom: 13.0,

                                              minZoom: 13.0,
                                            ),
                                            children: [
                                              TileLayer(
                                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                userAgentPackageName: 'com.example.app',
                                              ),
                                              MarkerLayer(markers: _markers),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4),
                                        child: Text(
                                          '© OpenStreetMap contributors',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: _buildFacilitiesList(hospitals, clinicsPharmacies, facilitiesNearby),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildFacilitiesList(List<Facility> hospitals, List<Facility> clinicsPharmacies, List<Facility> facilitiesNearby) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Nearby Facilities",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "${facilitiesNearby.length} found",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              // Hospitals & Health Centers
              if (hospitals.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hospitals & Health Centers",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ...hospitals.map(_buildFacilityBox),
                    ],
                  ),
                ),
              // Clinics & Pharmacies
              if (clinicsPharmacies.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Clinics & Pharmacies",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ...clinicsPharmacies.map(_buildFacilityBox),
                    ],
                  ),
                ),
              if (facilitiesNearby.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("No facilities nearby.", style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityBox(Facility facility) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  facility.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (facility.type.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: facility.type.toLowerCase().contains("hospital")
                        ? Colors.blue
                        : facility.type.toLowerCase().contains("pharmacy")
                            ? Colors.purple
                            : facility.type.toLowerCase().contains("clinic")
                                ? Colors.green
                                : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    facility.type,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
          if (facility.address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                facility.address,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          if (facility.phone.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.phone, size: 15, color: Colors.red),
                const SizedBox(width: 3),
                Flexible(child: Text(facility.phone, style: const TextStyle(fontSize: 13))),
              ],
            ),
          if (facility.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: facility.tags
                  .map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.grey[100],
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}