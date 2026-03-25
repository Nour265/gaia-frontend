import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ResultsPage extends StatefulWidget {
  final int age;
  final String gender;
  final List<String> symptoms;

  const ResultsPage({
    super.key,
    required this.age,
    required this.gender,
    required this.symptoms,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage>
    with TickerProviderStateMixin {
  static const LatLng _fallbackLocation = LatLng(37.7749, -122.4194);
  static const double _maxPreciseAccuracyMeters = 1500;
  static const List<_DoctorTemplate> _doctorTemplates = [
    _DoctorTemplate(
      name: 'Dr. Aisha Bello',
      specialty: 'Family Medicine',
      rating: 4.8,
      availability: 'Today - 4:30 PM',
      phone: '+1 (555) 210-3344',
      northKm: 1.1,
      eastKm: -0.5,
    ),
    _DoctorTemplate(
      name: 'Dr. Rahul Mehta',
      specialty: 'Internal Medicine',
      rating: 4.6,
      availability: 'Tomorrow - 10:00 AM',
      phone: '+1 (555) 330-1189',
      northKm: -1.7,
      eastKm: 1.2,
    ),
    _DoctorTemplate(
      name: 'Dr. Sofia Kim',
      specialty: 'Urgent Care',
      rating: 4.7,
      availability: 'Today - 6:15 PM',
      phone: '+1 (555) 908-4221',
      northKm: -2.6,
      eastKm: -1.4,
    ),
    _DoctorTemplate(
      name: 'Dr. Luis Ortega',
      specialty: 'Pulmonology',
      rating: 4.5,
      availability: 'Fri - 2:00 PM',
      phone: '+1 (555) 772-6043',
      northKm: 2.2,
      eastKm: 2.1,
    ),
  ];

  late Future<Map<String, dynamic>> _predictionFuture;
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();
  LatLng _userLocation = _fallbackLocation;
  late List<_Doctor> _doctors;
  String? _locationLabel;
  String? _mapAccessMessage;
  bool _isLocatingUser = false;
  bool _hasMapAccess = false;
  int _selectedDoctorIndex = 0;
  double _maxDistanceKm = 6;
  bool _mapReady = false;
  AnimationController? _mapAnimationController;

  bool get _supportsGeolocator {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return true;
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _doctors = _buildNearbyDoctors(_userLocation);
    // Call the ML API when page loads
    _predictionFuture = ApiService.createAssessment(
      age: widget.age,
      gender: widget.gender,
      symptoms: widget.symptoms
          .map((s) => {"name": s, "severity": 3}) // Default severity
          .toList(),
    );
    if (AuthSession.isLoggedIn) {
      _usePreciseDeviceLocation();
    } else {
      _mapAccessMessage = 'Log in to enable precise location.';
    }
  }

  @override
  void dispose() {
    _mapAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _resolveUserLocation() async {
    final profileLocation = AuthSession.user?.location?.trim();
    if (profileLocation == null || profileLocation.isEmpty) {
      return;
    }

    final parsed = _tryParseCoordinates(profileLocation);
    final resolved =
        parsed ??
        await _geocodeLocation(profileLocation) ??
        _approximateLocationFromText(profileLocation);
    if (!mounted) return;

    if (resolved == null) {
      setState(() {
        _locationLabel = profileLocation;
      });
      return;
    }

    setState(() {
      _userLocation = resolved;
      _doctors = _buildNearbyDoctors(resolved);
      _selectedDoctorIndex = 0;
      _locationLabel = profileLocation;
    });

    if (_mapReady) {
      _animateTo(resolved, 12.5);
    }
  }

  Future<void> _usePreciseDeviceLocation() async {
    if (_isLocatingUser) return;
    if (!AuthSession.isLoggedIn) {
      if (mounted) {
        setState(() {
          _hasMapAccess = false;
          _mapAccessMessage = 'Log in to enable precise location.';
        });
      }
      return;
    }
    if (!_supportsGeolocator) {
      if (mounted) {
        setState(() {
          _hasMapAccess = false;
          _mapAccessMessage =
              'Location access is not supported on this platform/runtime.';
        });
      }
      return;
    }

    setState(() {
      _isLocatingUser = true;
    });

    var mapAccessGranted = false;
    LatLng? precise;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        mapAccessGranted = false;
        _mapAccessMessage = 'Turn on device location services to unlock map.';
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        mapAccessGranted = false;
        _mapAccessMessage =
            'Allow location permission to unlock nearby doctors map.';
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));
      if (position.accuracy > _maxPreciseAccuracyMeters) {
        mapAccessGranted = false;
        _mapAccessMessage =
            'Could not get precise location yet. Please try again.';
        return;
      }
      precise = LatLng(position.latitude, position.longitude);
      mapAccessGranted = true;
      _mapAccessMessage = null;
    } on MissingPluginException {
      // Plugin unavailable on this runtime.
      mapAccessGranted = false;
      _mapAccessMessage = 'Location plugin is unavailable on this runtime.';
    } catch (_) {
      // Keep silent and preserve fallback/profile location.
      mapAccessGranted = false;
      _mapAccessMessage = 'Unable to fetch precise location. Please retry.';
    } finally {
      if (!mounted) return;

      setState(() {
        _isLocatingUser = false;
        _hasMapAccess = mapAccessGranted;
        if (mapAccessGranted && precise != null) {
          _userLocation = precise!;
          _doctors = _buildNearbyDoctors(precise!);
          _selectedDoctorIndex = 0;
          _locationLabel = "your precise location";
        }
      });

      if (mapAccessGranted && precise != null && _mapReady) {
        _animateTo(precise!, 13.2);
      }
    }
  }

  Future<void> _goToLoginForMapAccess() async {
    await Navigator.pushNamed(context, Routes.login);
    if (!mounted) return;
    setState(() {});
    if (AuthSession.isLoggedIn) {
      _usePreciseDeviceLocation();
    }
  }

  LatLng? _tryParseCoordinates(String locationText) {
    final match = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(locationText);
    if (match == null) {
      return null;
    }

    final lat = double.tryParse(match.group(1) ?? '');
    final lng = double.tryParse(match.group(2) ?? '');
    if (lat == null || lng == null) {
      return null;
    }
    if (lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    return LatLng(lat, lng);
  }

  Future<LatLng?> _geocodeLocation(String locationText) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': locationText,
        'format': 'jsonv2',
        'limit': '1',
      });
      final response = await http
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'gaia-symptom-checker/1.0',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) {
        return null;
      }

      final first = decoded.first;
      if (first is! Map<String, dynamic>) {
        return null;
      }

      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lng = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lng == null) {
        return null;
      }
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }

  LatLng? _approximateLocationFromText(String locationText) {
    final normalized = locationText.toLowerCase();
    const presets = <String, LatLng>{
      'beirut': LatLng(33.8938, 35.5018),
      'lebanon': LatLng(33.8547, 35.8623),
      'mazraa': LatLng(33.8825, 35.4950),
      'ras beirut': LatLng(33.9000, 35.4700),
      'mount lebanon': LatLng(33.8400, 35.6200),
      'baabda': LatLng(33.8339, 35.5442),
      'aley': LatLng(33.8078, 35.6081),
      'jounieh': LatLng(33.9811, 35.6178),
      'north': LatLng(34.4367, 35.8497),
      'tripoli': LatLng(34.4367, 35.8497),
      'zgharta': LatLng(34.3997, 35.8942),
      'bcharre': LatLng(34.2508, 36.0106),
      'south': LatLng(33.2700, 35.2000),
      'sidon': LatLng(33.5630, 35.3688),
      'tyre': LatLng(33.2704, 35.2038),
      'jezzine': LatLng(33.5417, 35.5844),
      'bekaa': LatLng(33.8500, 36.1000),
      'zahle': LatLng(33.8461, 35.9028),
      'baalbek': LatLng(34.0058, 36.2181),
      'anjar': LatLng(33.7278, 35.9300),
      'nabatieh': LatLng(33.3789, 35.4839),
      'bint jbeil': LatLng(33.1194, 35.4331),
      'marjayoun': LatLng(33.3603, 35.5911),
      'new york': LatLng(40.7128, -74.0060),
      'new york city': LatLng(40.7128, -74.0060),
      'buffalo': LatLng(42.8864, -78.8784),
      'rochester': LatLng(43.1566, -77.6088),
      'san francisco': LatLng(37.7749, -122.4194),
      'los angeles': LatLng(34.0522, -118.2437),
      'san diego': LatLng(32.7157, -117.1611),
      'california': LatLng(36.7783, -119.4179),
      'texas': LatLng(31.0000, -100.0000),
      'houston': LatLng(29.7604, -95.3698),
      'austin': LatLng(30.2672, -97.7431),
      'dallas': LatLng(32.7767, -96.7970),
      'florida': LatLng(27.6648, -81.5158),
      'miami': LatLng(25.7617, -80.1918),
      'orlando': LatLng(28.5383, -81.3792),
      'tampa': LatLng(27.9506, -82.4572),
      'united states': LatLng(39.8283, -98.5795),
      'jordan': LatLng(30.5852, 36.2384),
      'sweileh': LatLng(32.0246, 35.8578),
      'al jubeiha': LatLng(32.0313, 35.8868),
      'irbid': LatLng(32.5568, 35.8479),
      'ramtha': LatLng(32.5587, 36.0082),
      'bani ubayd': LatLng(32.5317, 35.8837),
      'zarqa': LatLng(32.0728, 36.0880),
      'russeifa': LatLng(32.0252, 36.0466),
      'hashemiya': LatLng(32.1319, 36.3742),
      'aqaba': LatLng(29.5321, 35.0063),
      'quweira': LatLng(29.8029, 35.3112),
      'dissi': LatLng(29.6126, 35.4922),
      'london': LatLng(51.5072, -0.1276),
      'paris': LatLng(48.8566, 2.3522),
      'dubai': LatLng(25.2048, 55.2708),
      'riyadh': LatLng(24.7136, 46.6753),
      'cairo': LatLng(30.0444, 31.2357),
      'amman': LatLng(31.9539, 35.9106),
    };

    for (final entry in presets.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  List<_Doctor> _buildNearbyDoctors(LatLng center) {
    final lngScale = max(cos(center.latitude * pi / 180).abs(), 0.2);

    return _doctorTemplates.map((template) {
      final lat = center.latitude + (template.northKm / 111.0);
      final lng = center.longitude + (template.eastKm / (111.0 * lngScale));

      return _Doctor(
        name: template.name,
        specialty: template.specialty,
        rating: template.rating,
        availability: template.availability,
        phone: template.phone,
        location: LatLng(lat, lng),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GaiaNavBarAppBar(),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _predictionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final data = snapshot.data!;
                  final filteredDoctors = _doctors.where((doctor) {
                    final km = _distance.as(
                      LengthUnit.Kilometer,
                      _userLocation,
                      doctor.location,
                    );
                    return km <= _maxDistanceKm;
                  }).toList();

                  final selectedIndex = _doctors.isEmpty
                      ? 0
                      : _selectedDoctorIndex.clamp(0, _doctors.length - 1);
                  final selectedDoctor = _doctors.isEmpty
                      ? null
                      : _doctors[selectedIndex];
                  final activeDoctor =
                      selectedDoctor != null &&
                          filteredDoctors.contains(selectedDoctor)
                      ? selectedDoctor
                      : (filteredDoctors.isNotEmpty
                            ? filteredDoctors.first
                            : null);
                  final badges = activeDoctor == null
                      ? const <String>[]
                      : _matchBadges(activeDoctor, data['risk_level']);
                  final matchScore = activeDoctor == null
                      ? null
                      : _matchScore(activeDoctor, data['risk_level']);

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 24.0,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 1000;
                          final isLoggedIn = AuthSession.isLoggedIn;
                          final canAccessMap = isLoggedIn && _hasMapAccess;

                          final detailsWidget = activeDoctor == null
                              ? Text(
                                  'No doctors within the selected radius. Try expanding the range.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              : _DoctorDetailsCard(
                                  doctor: activeDoctor,
                                  distanceKm: _distance.as(
                                    LengthUnit.Kilometer,
                                    _userLocation,
                                    activeDoctor.location,
                                  ),
                                  etaMinutes: _etaMinutes(
                                    _distance.as(
                                      LengthUnit.Kilometer,
                                      _userLocation,
                                      activeDoctor.location,
                                    ),
                                  ),
                                  matchScore: matchScore,
                                  badges: badges,
                                  onFocus: () =>
                                      _animateTo(activeDoctor.location, 14.2),
                                  onBook: () {
                                    if (!AuthSession.isLoggedIn) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please log in to book an appointment.',
                                          ),
                                        ),
                                      );
                                      Navigator.pushNamed(
                                        context,
                                        Routes.login,
                                      );
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Demo: booking flow would start here.',
                                        ),
                                      ),
                                    );
                                  },
                                );

                          final infoColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Top Prediction (Main Feature)
                              if (data['top_3_predictions'] != null &&
                                  (data['top_3_predictions'] as List)
                                      .isNotEmpty)
                                Column(
                                  children: [
                                    Text(
                                      'Predicted Condition',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppColors.gray[700],
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Card(
                                      color: AppColors.purple,
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 24,
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              (data['top_3_predictions'][0]
                                                      as Map)['disease'] ??
                                                  'Unknown',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Top 3 Predictions
                                    Text(
                                      'Alternative Predictions',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                            color: AppColors.gray[900],
                                          ),
                                    ),
                                    const SizedBox(height: 14),
                                    ...List.generate(
                                      (data['top_3_predictions'] as List)
                                          .length,
                                      (index) {
                                        final prediction =
                                            (data['top_3_predictions']
                                                    as List)[index]
                                                as Map;
                                        final purpleShades = [
                                          Colors.purple.shade700,
                                          Colors.purple.shade600,
                                          Colors.purple.shade400,
                                        ];
                                        final bgShades = [
                                          Colors.purple.shade100,
                                          Colors.purple.shade200,
                                          Colors.purple.shade200,
                                        ];
                                        final borderColor =
                                            purpleShades[index %
                                                purpleShades.length];
                                        final bgColor =
                                            bgShades[index % bgShades.length];

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: bgColor,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: borderColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${index + 1}. ${prediction['disease']}',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: AppColors
                                                                    .gray[900],
                                                              ),
                                                        ),
                                                        Text(
                                                              'Confidence: ${(prediction['probability'] * 100).toStringAsFixed(1)}%',
                                                              style: TextStyle(
                                                                color: Colors.grey.shade700,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              // Risk Level Card
                              Card(
                                color: _getRiskColor(data['risk_level']),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Risk Level Assessment',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white70,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        data['risk_level'],
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Explanation
                              Text(
                                'Assessment Summary',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                      color: AppColors.purple,
                                    ),
                              ),

                              const SizedBox(height: 24),
                              // Recommendation
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.orange[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.orange,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline,
                                          color: AppColors.orange,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Recommendation',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: AppColors.orange,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      data['recommendation'],
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            height: 1.6,
                                            color: AppColors.gray[900],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );

                          final requestPreciseLocationButton = SizedBox(
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: _isLocatingUser
                                  ? null
                                  : _usePreciseDeviceLocation,
                              icon: _isLocatingUser
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location, size: 16),
                              label: const Text('Use Precise Location'),
                            ),
                          );

                          final controls = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.pink[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.pink[800]!,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Filter Distance: ${_maxDistanceKm.toStringAsFixed(0)} km',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.pink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Slider(
                                value: _maxDistanceKm,
                                min: 1,
                                max: 12,
                                divisions: 11,
                                label:
                                    '${_maxDistanceKm.toStringAsFixed(0)} km',
                                onChanged: (value) {
                                  setState(() {
                                    _maxDistanceKm = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.pastelGreen.withAlpha(200),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.pastelGreen,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Found ${filteredDoctors.length} doctor${filteredDoctors.length != 1 ? 's' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.gray[900],
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              requestPreciseLocationButton,
                            ],
                          );

                          final mapSection = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nearby Doctors',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                      color: AppColors.purple,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.pastelBlue.withAlpha(150),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.turquoise[800]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  !isLoggedIn
                                      ? 'Log in to enable location and unlock the map.'
                                      : !_hasMapAccess
                                      ? (_mapAccessMessage ??
                                            'Allow precise location access to unlock the map.')
                                      : (_locationLabel == null
                                            ? 'Pan, zoom, and tap pins to match with doctors.'
                                            : 'Showing doctors near $_locationLabel.'),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.gray[900],
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (!canAccessMap)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray[100],
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    border: Border.all(
                                      color: AppColors.gray[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.lock_outline,
                                            color: AppColors.gray[800],
                                          ),
                                          const SizedBox(
                                            width: AppSpacing.sm,
                                          ),
                                          Expanded(
                                            child: Text(
                                              !isLoggedIn
                                                  ? 'Map access requires an account. Please log in first.'
                                                  : (_mapAccessMessage ??
                                                        'Map access is locked until precise location is available.'),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                color: AppColors.gray[900],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isLoggedIn) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        SizedBox(
                                          height: 40,
                                          child: ElevatedButton.icon(
                                            onPressed: _goToLoginForMapAccess,
                                            icon: const Icon(
                                              Icons.person_outline,
                                            ),
                                            label: const Text(
                                              'Log In To Unlock Map',
                                            ),
                                          ),
                                        ),
                                      ] else if (_supportsGeolocator) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        requestPreciseLocationButton,
                                      ],
                                    ],
                                  ),
                                )
                              else ...[
                                _DoctorMap(
                                  mapController: _mapController,
                                  userLocation: _userLocation,
                                  doctors: filteredDoctors,
                                  activeDoctor: activeDoctor,
                                  onReady: () {
                                    _mapReady = true;
                                    _mapController.move(_userLocation, 12.5);
                                  },
                                  onSelect: (index) {
                                    final selected = filteredDoctors[index];
                                    final originalIndex = _doctors.indexOf(
                                      selected,
                                    );
                                    if (originalIndex < 0) {
                                      return;
                                    }
                                    setState(() {
                                      _selectedDoctorIndex = originalIndex;
                                    });
                                    _animateTo(selected.location, 13.8);
                                  },
                                  height: isWide ? 300 : 340,
                                ),
                                const SizedBox(height: 12),
                                controls,
                                const SizedBox(height: 16),
                                detailsWidget,
                              ],
                            ],
                          );

                          if (!isWide) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                infoColumn,
                                const SizedBox(height: 24),
                                mapSection,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 500,
                                    ),
                                    child: infoColumn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              SizedBox(width: 360, child: mapSection),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _animateTo(LatLng target, double zoom) {
    if (!_mapReady) {
      _mapController.move(target, zoom);
      return;
    }
    _mapAnimationController?.dispose();
    final beginCenter = _mapController.camera.center;
    final beginZoom = _mapController.camera.zoom;
    _mapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final curve = CurvedAnimation(
      parent: _mapAnimationController!,
      curve: Curves.easeOutCubic,
    );
    _mapAnimationController!.addListener(() {
      final t = curve.value;
      final lat =
          beginCenter.latitude + (target.latitude - beginCenter.latitude) * t;
      final lng =
          beginCenter.longitude +
          (target.longitude - beginCenter.longitude) * t;
      final z = beginZoom + (zoom - beginZoom) * t;
      _mapController.move(LatLng(lat, lng), z);
    });
    _mapAnimationController!.forward();
  }

  int _etaMinutes(double distanceKm) {
    final base = distanceKm * 2.2 + 4;
    return max(5, base.round());
  }

  List<String> _matchBadges(_Doctor doctor, String riskLevel) {
    final symptoms = widget.symptoms.map((s) => s.toLowerCase()).toList();
    bool hasAny(List<String> keys) =>
        symptoms.any((s) => keys.any((k) => s.contains(k)));

    final hasResp = hasAny(['cough', 'breath', 'chest', 'wheez', 'asthma']);
    final hasDigestive = hasAny([
      'nausea',
      'vomit',
      'stomach',
      'abdominal',
      'diarrhea',
    ]);
    final hasPain = hasAny(['pain', 'ache', 'headache', 'migraine']);

    final badges = <String>[];
    if (doctor.specialty.contains('Pulmonology') && hasResp) {
      badges.add('Respiratory fit');
    }
    if (doctor.specialty.contains('Urgent Care') &&
        (riskLevel == 'High' || riskLevel == 'Medium')) {
      badges.add('Rapid access');
    }
    if (doctor.specialty.contains('Family') && !hasResp) {
      badges.add('Whole-person care');
    }
    if (doctor.specialty.contains('Internal') && (hasDigestive || hasPain)) {
      badges.add('Complex symptoms');
    }
    if (badges.isEmpty) {
      badges.add('General match');
    }
    if (riskLevel == 'High') {
      badges.add('Priority');
    }
    return badges.take(3).toList();
  }

  double _matchScore(_Doctor doctor, String riskLevel) {
    var score = 72.0;
    final badges = _matchBadges(doctor, riskLevel);
    if (badges.any((b) => b.contains('Respiratory'))) score += 10;
    if (badges.any((b) => b.contains('Rapid'))) score += 8;
    if (badges.any((b) => b.contains('Complex'))) score += 6;
    if (riskLevel == 'High') score += 4;
    if (doctor.rating > 4.6) score += 4;
    return score.clamp(60, 98);
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _Doctor {
  const _Doctor({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.availability,
    required this.phone,
    required this.location,
  });

  final String name;
  final String specialty;
  final double rating;
  final String availability;
  final String phone;
  final LatLng location;
}

class _DoctorTemplate {
  const _DoctorTemplate({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.availability,
    required this.phone,
    required this.northKm,
    required this.eastKm,
  });

  final String name;
  final String specialty;
  final double rating;
  final String availability;
  final String phone;
  final double northKm;
  final double eastKm;
}

class _DoctorMap extends StatelessWidget {
  const _DoctorMap({
    required this.mapController,
    required this.userLocation,
    required this.doctors,
    required this.activeDoctor,
    required this.onReady,
    required this.onSelect,
    this.height = 320,
  });

  final MapController mapController;
  final LatLng userLocation;
  final List<_Doctor> doctors;
  final _Doctor? activeDoctor;
  final VoidCallback onReady;
  final ValueChanged<int> onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: userLocation,
        width: 16,
        height: 16,
        child: const _UserDot(),
      ),
      for (var i = 0; i < doctors.length; i++)
        Marker(
          point: doctors[i].location,
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: _DoctorPin(
              selected: activeDoctor == doctors[i],
              label: doctors[i].name.split(' ').first,
            ),
          ),
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 12.5,
              onMapReady: onReady,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gaia',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorDetailsCard extends StatelessWidget {
  const _DoctorDetailsCard({
    required this.doctor,
    required this.distanceKm,
    required this.etaMinutes,
    required this.matchScore,
    required this.badges,
    required this.onFocus,
    required this.onBook,
  });

  final _Doctor doctor;
  final double distanceKm;
  final int etaMinutes;
  final double? matchScore;
  final List<String> badges;
  final VoidCallback onFocus;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${doctor.specialty} - ${distanceKm.toStringAsFixed(1)} km away',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text('${doctor.rating} rating', style: textTheme.bodyMedium),
                  const SizedBox(width: 20),
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 4),
                  Text(doctor.availability, style: textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.route, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'ETA ~ $etaMinutes min (fastest)',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 12),
                  if (matchScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        'Match ${matchScore!.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges
                      .map(
                        (badge) => Chip(
                          label: Text(
                            badge,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.indigo.shade50,
                          side: BorderSide(color: Colors.indigo.shade200),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: onBook,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Book Appointment'),
                    ),
                  ),
                  IconButton(
                    onPressed: onFocus,
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Focus on map',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorPin extends StatelessWidget {
  const _DoctorPin({required this.selected, required this.label});

  final bool selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _PulsingPin(active: selected, label: label);
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      width: 10,
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _PulsingPin extends StatefulWidget {
  const _PulsingPin({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  State<_PulsingPin> createState() => _PulsingPinState();
}

class _PulsingPinState extends State<_PulsingPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingPin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pin = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_pin,
          size: widget.active ? 38 : 30,
          color: widget.active ? Colors.redAccent : Colors.red.shade400,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Text(widget.label, style: const TextStyle(fontSize: 11)),
        ),
      ],
    );

    if (!widget.active) {
      return pin;
    }

    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              return Container(
                width: 24 + (t * 36),
                height: 24 + (t * 36),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.15 * (1 - t)),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.4 * (1 - t)),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = (_controller.value + 0.5) % 1.0;
              return Container(
                width: 20 + (t * 28),
                height: 20 + (t * 28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.12 * (1 - t)),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.35 * (1 - t)),
                  ),
                ),
              );
            },
          ),
          pin,
        ],
      ),
    );
  }
}
