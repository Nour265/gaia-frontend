import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

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

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
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
  static const double _maxPreciseAccuracyMeters = 50000;
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
  double _maxDistanceKm = 30;
  bool _mapReady = false;
  AnimationController? _mapAnimationController;
  String? _predictedCondition;
  String? _riskLevel;
  bool _isBooking = false;

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
    _fetchRealDoctors(resolved);
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

      if (mapAccessGranted && precise != null) {
        if (_mapReady) _animateTo(precise, 13.2);
        _fetchRealDoctors(precise);
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
        id: 0,
        name: template.name,
        specialty: template.specialty,
        rating: template.rating,
        availability: template.availability,
        phone: template.phone,
        location: LatLng(lat, lng),
      );
    }).toList();
  }
  Future<void> _fetchRealDoctors(LatLng center) async {
    try {
      final raw = await ApiService.getNearbyDoctors(
        lat: center.latitude,
        lng: center.longitude,
        condition: _predictedCondition,
        riskLevel: _riskLevel,
        radiusKm: 100,
      );
      if (!mounted) return;
      final fetched = raw.map<_Doctor>((d) {
        return _Doctor(
          id: (d['id'] as int?) ?? 0,
          name: d['name'] as String? ?? 'Dr. Unknown',
          specialty: d['specialty'] as String? ?? 'General Practice',
          rating: ((d['rating'] as num?) ?? 4.5).toDouble(),
          availability: 'Contact to schedule',
          phone: d['phone'] as String? ?? '',
          location: LatLng(
            (d['latitude'] as num).toDouble(),
            (d['longitude'] as num).toDouble(),
          ),
          distanceKm: ((d['distance_km'] as num?) ?? 50.0).toDouble(),
          isSpecialtyMatch: (d['is_specialty_match'] as bool?) ?? false,
        );
      }).toList();

      if (fetched.isNotEmpty && mounted) {
        setState(() {
          _doctors = fetched;
          _selectedDoctorIndex = 0;
        });
        if (_mapReady) _animateTo(center, 12.5);
      }
    } catch (_) {
      // Fall back silently to the template-based list already shown
    }
  }

  Future<void> _bookAppointment(_Doctor doctor, String condition) async {
    if (doctor.id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is a demo doctor — add real doctors via the admin panel.')),
      );
      return;
    }
    setState(() => _isBooking = true);
    try {
      await ApiService.bookAppointment(doctorId: doctor.id, condition: condition);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked with ${doctor.name}!'),
          backgroundColor: Colors.green.shade700,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/my-appointments'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _generateAndShareReport(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    
    // --- 1. LOAD THE IMAGE FROM ASSETS ---
    final ByteData imageBytes = await rootBundle.load('assets/images/logo.png');
    final Uint8List imageData = imageBytes.buffer.asUint8List();
    final logo = pw.MemoryImage(imageData);

    // Generate a timestamp and a random Reference ID
    final String date = DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now());
    final String refId = 'GAIA-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final topPrediction = data['top_3_predictions'][0];
    final riskLevel = data['risk_level'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        
        // --- PROPER DISCLAIMER FOOTER ---
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Text(
                'MEDICAL DISCLAIMER: This document was generated by an artificial intelligence triage model. It is for informational purposes only and does not constitute a formal medical diagnosis. Always consult a licensed healthcare professional for proper medical evaluation.',
                style: pw.TextStyle(
                  fontSize: 8, 
                  color: PdfColors.grey600, 
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
        
        build: (context) => [
          // --- HEADER WITH LOGO ---
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // --- 2. DISPLAY LOGO ---
                  pw.Image(logo, width: 45, height: 45), 
                  pw.SizedBox(width: 15),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('GAIA HEALTH', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                      pw.SizedBox(height: 4),
                      pw.Text('Rafik Hariri University - Medical AI Triage', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      pw.Text('Beirut, Lebanon', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('ASSESSMENT REPORT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Ref ID: $refId', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 2, color: PdfColors.indigo100, height: 40),

          // --- PATIENT PROFILE ---
          pw.Text('PATIENT PROFILE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text('Age: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${widget.age} years   |   '),
              pw.Text('Gender: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(widget.gender.toUpperCase()),
            ],
          ),
          pw.SizedBox(height: 30),

          // --- CLINICAL SUMMARY ---
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: riskLevel == 'Critical' || riskLevel == 'High' 
                  ? PdfColors.red50 
                  : (riskLevel == 'Medium' ? PdfColors.orange50 : PdfColors.blue50),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(
                color: riskLevel == 'Critical' || riskLevel == 'High' 
                    ? PdfColors.red200 
                    : (riskLevel == 'Medium' ? PdfColors.orange200 : PdfColors.blue200),
              )
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PRIMARY ASSESSMENT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text(topPrediction['disease'], style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Risk Level: ${riskLevel.toUpperCase()}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                pw.SizedBox(height: 15),
                pw.Text('Recommended Action:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text(data['recommendation'], style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5)),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // --- REPORTED SYMPTOMS ---
          pw.Text('REPORTED SYMPTOMS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.symptoms.map((s) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                border: pw.Border.all(color: PdfColors.grey300)
              ),
              child: pw.Text(s, style: const pw.TextStyle(fontSize: 10)),
            )).toList(),
          ),
          pw.SizedBox(height: 30),

          // --- SECONDARY PREDICTIONS ---
          if ((data['top_3_predictions'] as List).length > 1) ...[
            pw.Text('SECONDARY POSSIBILITIES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
            pw.SizedBox(height: 10),
            ...List.generate((data['top_3_predictions'] as List).length - 1, (index) {
              final pred = data['top_3_predictions'][index + 1];
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  children: [
                    pw.Text('• ${pred['disease']}', style: const pw.TextStyle(fontSize: 12)),
                    pw.Spacer(), 
                    pw.Text('Probability: ${(pred['probability'] * 100).toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  ]
                )
              );
            }),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Gaia_Assessment_$refId.pdf',
    );
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
                  // Capture predicted condition + risk level once the future resolves
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final preds = data['top_3_predictions'] as List?;
                    final risk = data['risk_level'] as String?;
                    final needsRefetch = _riskLevel == null && risk != null;
                    if (preds != null && preds.isNotEmpty && _predictedCondition == null) {
                      setState(() {
                        _predictedCondition = (preds.first as Map)['disease'] as String?;
                        _riskLevel = risk;
                      });
                      if (needsRefetch) _fetchRealDoctors(_userLocation);
                    } else if (needsRefetch) {
                      setState(() => _riskLevel = risk);
                      _fetchRealDoctors(_userLocation);
                    }
                  });
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
                                    _bookAppointment(
                                      activeDoctor,
                                      _predictedCondition ?? '',
                                    );
                                  },
                                );

                          final infoColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Primary Prediction Header
                              Text(
                                'Assessment Results',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blueGrey.shade900,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 2. Primary Prediction Card
                              if (data['top_3_predictions'] != null && (data['top_3_predictions'] as List).isNotEmpty)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.indigo.shade600, Colors.purple.shade500],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.indigo.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 40),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Top Match',
                                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (data['top_3_predictions'][0] as Map)['disease'] ?? 'Unknown',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Text(
                                          'Confidence: ${((data['top_3_predictions'][0] as Map)['probability'] * 100).toStringAsFixed(1)}%',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 24),

                              // 3. Risk Level and Recommendation Side-by-Side
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: _getRiskColor(data['risk_level']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _getRiskColor(data['risk_level']).withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.warning_rounded,
                                            color: _getRiskColor(data['risk_level']),
                                            size: 28,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Risk Level',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data['risk_level'],
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: _getRiskColor(data['risk_level']),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.blue.shade100),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.lightbulb_circle, color: Colors.blue.shade700, size: 24),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Next Steps',
                                                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blue.shade900, fontSize: 16),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            data['recommendation'],
                                            style: TextStyle(height: 1.4, color: Colors.blue.shade800, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 4. Alternative Predictions with Progress Bars
                              if (data['top_3_predictions'] != null && (data['top_3_predictions'] as List).length > 1) ...[
                                Text(
                                  'Other Possibilities',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blueGrey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(
                                  (data['top_3_predictions'] as List).length - 1,
                                  (index) {
                                    final prediction = (data['top_3_predictions'] as List)[index + 1] as Map;
                                    final prob = prediction['probability'] as double;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade200),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.06),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 2}',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 16),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  prediction['disease'],
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                                ),
                                                const SizedBox(height: 8),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: prob,
                                                    backgroundColor: Colors.grey.shade200,
                                                    color: Colors.indigo.shade400,
                                                    minHeight: 6,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '${(prob * 100).toStringAsFixed(1)}%',
                                            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.indigo.shade700),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                              const SizedBox(height: 32),

                              // 5. Generate Report Button
                              ElevatedButton.icon(
                                onPressed: () => _generateAndShareReport(data),
                                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                                label: const Text(
                                  'Save / Share Report',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade600,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.indigo.withOpacity(0.4),
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
                                max: 100,
                                divisions: 99,
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
                                if (filteredDoctors.length > 1) ...[
                                  const SizedBox(height: 16),
                                  _CollapsibleDoctorList(
                                    doctors: filteredDoctors,
                                    activeDoctor: activeDoctor,
                                    userLocation: _userLocation,
                                    distance: _distance,
                                    riskLevel: data['risk_level'] as String,
                                    etaMinutes: _etaMinutes,
                                    matchScore: _matchScore,
                                    matchBadges: _matchBadges,
                                    onSelect: (doctor) {
                                      final orig = _doctors.indexOf(doctor);
                                      if (orig >= 0) {
                                        setState(() => _selectedDoctorIndex = orig);
                                        _animateTo(doctor.location, 14.2);
                                      }
                                    },
                                    onFocus: (doctor) => _animateTo(doctor.location, 14.2),
                                    onBook: (doctor) => _bookAppointment(
                                      doctor,
                                      _predictedCondition ?? '',
                                    ),
                                  ),
                                ],
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
    double score = doctor.isSpecialtyMatch ? 72.0 : 20.0;
    final dist = (doctor.distanceKm ?? 50.0).clamp(0.0, 100.0);
    score += 20.0 * (1 - dist / 100.0);
    if (riskLevel == 'High' &&
        (doctor.specialty.toLowerCase().contains('urgent') ||
         doctor.specialty.toLowerCase().contains('emergency') ||
         doctor.specialty.toLowerCase().contains('internal medicine'))) {
      score += 8;
    }
    return score.clamp(15.0, 98.0);
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
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.availability,
    required this.phone,
    required this.location,
    this.distanceKm,
    this.isSpecialtyMatch = false,
  });

  final int id;
  final String name;
  final String specialty;
  final double rating;
  final String availability;
  final String phone;
  final LatLng location;
  final double? distanceKm;
  final bool isSpecialtyMatch;
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

// ── Collapsible doctor list ───────────────────────────────────────────────────

class _CollapsibleDoctorList extends StatefulWidget {
  const _CollapsibleDoctorList({
    required this.doctors,
    required this.activeDoctor,
    required this.userLocation,
    required this.distance,
    required this.riskLevel,
    required this.etaMinutes,
    required this.matchScore,
    required this.matchBadges,
    required this.onSelect,
    required this.onFocus,
    required this.onBook,
  });

  final List<_Doctor> doctors;
  final _Doctor? activeDoctor;
  final LatLng userLocation;
  final Distance distance;
  final String riskLevel;
  final int Function(double) etaMinutes;
  final double Function(_Doctor, String) matchScore;
  final List<String> Function(_Doctor, String) matchBadges;
  final void Function(_Doctor) onSelect;
  final void Function(_Doctor) onFocus;
  final void Function(_Doctor) onBook;

  @override
  State<_CollapsibleDoctorList> createState() => _CollapsibleDoctorListState();
}

class _CollapsibleDoctorListState extends State<_CollapsibleDoctorList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.purple.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.purple.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.people_alt_outlined, color: AppColors.purple, size: 20),
                const SizedBox(width: 10),
                Text(
                  'All Matching Doctors (${widget.doctors.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, color: AppColors.purple),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 8),
              for (final doctor in widget.doctors)
                _DoctorListTile(
                  doctor: doctor,
                  isSelected: doctor == widget.activeDoctor,
                  distanceKm: widget.distance.as(
                    LengthUnit.Kilometer,
                    widget.userLocation,
                    doctor.location,
                  ),
                  etaMinutes: widget.etaMinutes(widget.distance.as(
                    LengthUnit.Kilometer,
                    widget.userLocation,
                    doctor.location,
                  )),
                  matchScore: widget.matchScore(doctor, widget.riskLevel),
                  badges: widget.matchBadges(doctor, widget.riskLevel),
                  onTap: () => widget.onSelect(doctor),
                  onFocus: () => widget.onFocus(doctor),
                  onBook: () => widget.onBook(doctor),
                ),
            ],
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}

// ── Compact doctor list tile (expandable) ────────────────────────────────────

class _DoctorListTile extends StatefulWidget {
  const _DoctorListTile({
    required this.doctor,
    required this.isSelected,
    required this.distanceKm,
    required this.etaMinutes,
    required this.matchScore,
    required this.badges,
    required this.onTap,
    required this.onFocus,
    required this.onBook,
  });

  final _Doctor doctor;
  final bool isSelected;
  final double distanceKm;
  final int etaMinutes;
  final double? matchScore;
  final List<String> badges;
  final VoidCallback onTap;
  final VoidCallback onFocus;
  final VoidCallback onBook;

  @override
  State<_DoctorListTile> createState() => _DoctorListTileState();
}

class _DoctorListTileState extends State<_DoctorListTile> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _DoctorListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-collapse when another doctor is selected
    if (!widget.isSelected && oldWidget.isSelected) {
      setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isSelected ? AppColors.purple : Colors.grey.shade200,
          width: widget.isSelected ? 2 : 1,
        ),
      ),
      color: widget.isSelected ? AppColors.purple.withValues(alpha: 0.04) : null,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              widget.onTap();
              setState(() => _expanded = !_expanded);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: widget.isSelected
                        ? AppColors.purple.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    child: Icon(
                      Icons.local_hospital_outlined,
                      size: 20,
                      color: widget.isSelected ? AppColors.purple : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctor.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.isSelected ? AppColors.purple : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.doctor.specialty,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.distanceKm.toStringAsFixed(1)} km away',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _DoctorDetailsCard(
                doctor: widget.doctor,
                distanceKm: widget.distanceKm,
                etaMinutes: widget.etaMinutes,
                matchScore: widget.matchScore,
                badges: widget.badges,
                onFocus: widget.onFocus,
                onBook: widget.onBook,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => onSelect(i),
            behavior: HitTestBehavior.opaque,
            child: _DoctorPin(
              selected: activeDoctor == doctors[i],
              label: doctors[i].name.split(' ').last,
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
      width: 80,
      height: 80,
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
