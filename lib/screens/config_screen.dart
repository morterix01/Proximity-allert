import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/neon_button.dart';
import '../widgets/premium_text_field.dart';
import 'cookie_screen.dart';
import 'location_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ntfyController = TextEditingController();
  String _audioLabel = "Predefinito";

  @override
  void initState() {
    super.initState();
    _emailController.text = _storage.email;
    _ntfyController.text = _storage.ntfyTopic;
    if (_storage.isCustomAudio) {
      _audioLabel = "Personalizzato";
    }
  }

  void _chooseAudio() async {
    setState(() {
      _audioLabel = "Personalizzato";
    });
    await _storage.setCustomAudio(true);
  }

  void _saveAndExit() async {
    await _storage.setEmail(_emailController.text);
    await _storage.setNtfyTopic(_ntfyController.text);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              PremiumTextField(
                hintText: 'Email Google',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              PremiumTextField(
                hintText: 'Ntfy Topic',
                controller: _ntfyController,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      text: 'SUONO ALLARME',
                      onPressed: _chooseAudio,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    _audioLabel,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              NeonButton(
                text: 'GESTIONE COOKIE',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CookieScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              NeonButton(
                text: 'GESTIONE LUOGHI',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LocationScreen()),
                  );
                },
              ),
              const SizedBox(height: 40),
              NeonButton(
                text: 'SALVA E ESCI',
                onPressed: _saveAndExit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
