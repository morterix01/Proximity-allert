import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/location.dart';
import '../widgets/neon_button.dart';
import '../widgets/premium_text_field.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _radController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  List<MonitoredLocation> _locations = [];

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _locations = _storage.getLocations();
    });
  }

  void _removeLoc(int index) async {
    _locations.removeAt(index);
    await _storage.saveLocations(_locations);
    _refreshList();
  }

  void _addLoc() async {
    final name = _nameController.text.trim();
    final radStr = _radController.text.trim();
    final latStr = _latController.text.trim().replaceAll(',', '.');
    final lonStr = _lonController.text.trim().replaceAll(',', '.');

    if (name.isEmpty || radStr.isEmpty || latStr.isEmpty || lonStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("COMPILA TUTTO!")),
      );
      return;
    }

    try {
      final rad = int.parse(radStr);
      final lat = double.parse(latStr);
      final lon = double.parse(lonStr);

      _locations.add(MonitoredLocation(
        name: name,
        lat: lat,
        lon: lon,
        radiusMeters: rad,
      ));

      await _storage.saveLocations(_locations);

      _nameController.clear();
      _radController.clear();
      _latController.clear();
      _lonController.clear();

      _refreshList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ERRORE NUMERI!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'GESTIONE LUOGHI',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final loc = _locations[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${loc.name} (${loc.radiusMeters}m)\n${loc.lat}, ${loc.lon}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF4D4D)),
                            onPressed: () => _removeLoc(index),
                            child: const Text("Rimuovi"),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: PremiumTextField(
                          hintText: 'Nome', controller: _nameController)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: PremiumTextField(
                          hintText: 'Raggio(m)',
                          controller: _radController,
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: PremiumTextField(
                          hintText: 'Lat',
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: PremiumTextField(
                          hintText: 'Lon',
                          controller: _lonController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true))),
                ],
              ),
              const SizedBox(height: 10),
              NeonButton(
                text: 'AGGIUNGI LUOGO',
                onPressed: _addLoc,
              ),
              const SizedBox(height: 10),
              NeonButton(
                text: 'INDIETRO',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
