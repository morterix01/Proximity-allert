import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/storage_service.dart';
import '../services/google_location_service.dart';
import '../models/person.dart';
import '../widgets/glass_card.dart';
import '../widgets/neon_button.dart';
import 'config_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storage = StorageService();
  final GoogleLocationService _locationService = GoogleLocationService();
  final Distance _distance = const Distance();

  bool isRunning = false;
  String lastUpdate = "Mai";
  List<Person> people = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    isRunning = _storage.isMonitoring;
    if (isRunning) {
      _startLocalPolling();
    }
  }

  void _startLocalPolling() {
    _fetchData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchData();
    });
  }

  void _stopLocalPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> _fetchData() async {
    final fetchedPeople = await _locationService.getSharedPeople();
    if (mounted) {
      setState(() {
        people = fetchedPeople;
        lastUpdate = DateTime.now().toString().split('.').first;
      });
    }
  }

  Future<void> _toggleMonitoring() async {
    if (kIsWeb) {
      if (isRunning) {
        _stopLocalPolling();
        setState(() => isRunning = false);
      } else {
        await _storage.setMonitoring(true);
        _startLocalPolling();
        setState(() => isRunning = true);
      }
      return;
    }

    final service = FlutterBackgroundService();
    bool isRunningNow = await service.isRunning();

    if (isRunningNow) {
      service.invoke("stopService");
      _stopLocalPolling();
      setState(() {
        isRunning = false;
      });
    } else {
      await _storage.setMonitoring(true);
      service.startService();
      _startLocalPolling();
      setState(() {
        isRunning = true;
      });
    }
  }

  @override
  void dispose() {
    _stopLocalPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = _storage.getLocations();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Stack(
        children: [
          // Modern background gradient blobs
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF00F2FF).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4D).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Blur layer to create glass effect over background blobs
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox(),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'DASHBOARD V6',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFF00F2FF),
                    ),
                  ),
                  const SizedBox(height: 30),
              GlassCard(
                height: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isRunning ? "ATTIVO" : "INATTIVO",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Update: $lastUpdate",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];

                    double closestDist = double.infinity;
                    String closestLocName = "Nessuna";

                    for (var loc in locations) {
                      final d = _distance.as(
                          LengthUnit.Meter,
                          LatLng(person.latitude, person.longitude),
                          LatLng(loc.lat, loc.lon));
                      if (d < closestDist) {
                        closestDist = d;
                        closestLocName = loc.name;
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            closestLocName == "Nessuna"
                                ? "Nessun luogo configurato"
                                : "Vicino a: $closestLocName (${closestDist.toStringAsFixed(0)}m)",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              NeonButton(
                text: isRunning ? 'STOP' : 'START',
                baseColor: isRunning
                    ? const Color(0xFFFF4D4D)
                    : const Color(0xFF00F2FF),
                onPressed: _toggleMonitoring,
              ),
              const SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ConfigScreen()),
                    ).then((_) => setState(() {})); 
                  },
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  label: const Text(
                    'IMPOSTAZIONI',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}
