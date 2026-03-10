import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
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

class _ResultsPageState extends State<ResultsPage> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _predictionFuture;
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();
  int _selectedDoctorIndex = 0;
  double _maxDistanceKm = 6;
  bool _mapReady = false;
  AnimationController? _mapAnimationController;
  final LatLng _userLocation = const LatLng(37.7749, -122.4194);

  final List<_Doctor> _doctors = const [
    _Doctor(
      name: 'Dr. Aisha Bello',
      specialty: 'Family Medicine',
      distanceKm: 1.2,
      rating: 4.8,
      availability: 'Today · 4:30 PM',
      phone: '+1 (555) 210-3344',
      location: LatLng(37.7792, -122.4291),
    ),
    _Doctor(
      name: 'Dr. Rahul Mehta',
      specialty: 'Internal Medicine',
      distanceKm: 2.4,
      rating: 4.6,
      availability: 'Tomorrow · 10:00 AM',
      phone: '+1 (555) 330-1189',
      location: LatLng(37.7684, -122.4089),
    ),
    _Doctor(
      name: 'Dr. Sofia Kim',
      specialty: 'Urgent Care',
      distanceKm: 3.1,
      rating: 4.7,
      availability: 'Today · 6:15 PM',
      phone: '+1 (555) 908-4221',
      location: LatLng(37.7645, -122.4319),
    ),
    _Doctor(
      name: 'Dr. Luis Ortega',
      specialty: 'Pulmonology',
      distanceKm: 4.8,
      rating: 4.5,
      availability: 'Fri · 2:00 PM',
      phone: '+1 (555) 772-6043',
      location: LatLng(37.7848, -122.4012),
    ),
  ];


  @override
  void initState() {
    super.initState();
    // Call the ML API when page loads
    _predictionFuture = ApiService.createAssessment(
      age: widget.age,
      gender: widget.gender,
      symptoms: widget.symptoms
          .map((s) => {"name": s, "severity": 3}) // Default severity
          .toList(),
    );
  }

  @override
  void dispose() {
    _mapAnimationController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Results'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _predictionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
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

            final selectedDoctor = _doctors[_selectedDoctorIndex];
            final activeDoctor = filteredDoctors.contains(selectedDoctor)
                ? selectedDoctor
                : (filteredDoctors.isNotEmpty ? filteredDoctors.first : null);
            final badges = activeDoctor == null
                ? const <String>[]
                : _matchBadges(activeDoctor, data['risk_level']);
            final matchScore = activeDoctor == null
                ? null
                : _matchScore(activeDoctor, data['risk_level']);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 1000;

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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please log in to book an appointment.',
                                    ),
                                  ),
                                );
                                Navigator.pushNamed(context, Routes.login);
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Risk Level Card
                        Card(
                          color: _getRiskColor(data['risk_level']),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Risk Level',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['risk_level'],
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Confidence Score
                        Text(
                          'Confidence: ${(data['probability'] * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        // Explanation
                        Text(
                          'Assessment',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(data['explanation']),
                        const SizedBox(height: 20),
                        // Recommendation
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommendation',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(data['recommendation']),
                            ],
                          ),
                        ),
                      ],
                    );

                    final controls = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Max distance: ${_maxDistanceKm.toStringAsFixed(0)} km',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Slider(
                          value: _maxDistanceKm,
                          min: 1,
                          max: 12,
                          divisions: 11,
                          label: '${_maxDistanceKm.toStringAsFixed(0)} km',
                          onChanged: (value) {
                            setState(() {
                              _maxDistanceKm = value;
                            });
                          },
                        ),
                        Text(
                          'Showing ${filteredDoctors.length} doctors',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );

                    final mapSection = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nearby Doctors',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Interactive demo: pan, zoom, and tap a pin to match a doctor.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        _DoctorMap(
                          mapController: _mapController,
                          userLocation: _userLocation,
                          doctors: filteredDoctors,
                          activeDoctor: activeDoctor,
                          onReady: () => _mapReady = true,
                          onSelect: (index) {
                            final selected = filteredDoctors[index];
                            final originalIndex = _doctors.indexOf(selected);
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
                    );

                    if (!isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                        Expanded(child: infoColumn),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 360,
                          child: mapSection,
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }
        },
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
          beginCenter.longitude + (target.longitude - beginCenter.longitude) * t;
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
    final hasDigestive =
        hasAny(['nausea', 'vomit', 'stomach', 'abdominal', 'diarrhea']);
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
    required this.distanceKm,
    required this.rating,
    required this.availability,
    required this.phone,
    required this.location,
  });

  final String name;
  final String specialty;
  final double distanceKm;
  final double rating;
  final String availability;
  final String phone;
  final LatLng location;
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: textTheme.titleMedium,
              ),
            const SizedBox(height: 4),
            Text(
              '${doctor.specialty} · ${distanceKm.toStringAsFixed(1)} km away',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${doctor.rating} rating'),
                const SizedBox(width: 16),
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 4),
                Text(doctor.availability),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.route, size: 18),
                const SizedBox(width: 4),
                Text('ETA ~ $etaMinutes min (fastest)'),
                const SizedBox(width: 12),
                if (matchScore != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'Match ${matchScore!.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: badges
                    .map(
                      (badge) => Chip(
                        label: Text(badge),
                        backgroundColor: Colors.indigo.shade50,
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: onBook,
                      child: const Text('Book Appointment'),
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
  const _DoctorPin({
    required this.selected,
    required this.label,
  });

  final bool selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _PulsingPin(
      active: selected,
      label: label,
    );
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
  const _PulsingPin({
    required this.active,
    required this.label,
  });

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
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
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
          child: Text(
            widget.label,
            style: const TextStyle(fontSize: 11),
          ),
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
