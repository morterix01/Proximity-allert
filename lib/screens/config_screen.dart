import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
    _audioLabel = _storage.audioName;
  }

  void _chooseAudio() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La scelta dei file è disponibile solo su iPhone reale."),
          backgroundColor: Color(0xFFFF4D4D),
        ),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        String name = result.files.single.name;
        setState(() {
          _audioLabel = name;
        });
        await _storage.setAudioPath(path);
        await _storage.setAudioName(name);
        await _storage.setCustomAudio(true);
      }
    } catch (e) {
      debugPrint("Errore selezione file: $e");
    }
  }

  void _resetAudio() async {
    setState(() {
      _audioLabel = "Allarme Labs";
    });
    await _storage.setAudioPath('');
    await _storage.setAudioName('Allarme Labs');
    await _storage.setCustomAudio(false);
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
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF00F2FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4D).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: const SizedBox(),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'IMPOSTAZIONI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer for centering
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ACCOUNT & NOTIFICHE",
                                style: TextStyle(
                                  color: Color(0xFF00F2FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              PremiumTextField(
                                hintText: 'Email Google',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 15),
                              PremiumTextField(
                                hintText: 'Ntfy Topic',
                                controller: _ntfyController,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.music_note, color: Colors.white70),
                                  const SizedBox(width: 15),
                                  const Expanded(
                                    child: Text(
                                      "Suono Allarme",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    _audioLabel,
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              NeonButton(
                                text: 'CAMBIA SUONO',
                                onPressed: _chooseAudio,
                              ),
                              const SizedBox(height: 10),
                              if (_audioLabel != "Allarme Labs")
                                TextButton(
                                  onPressed: _resetAudio,
                                  child: const Text(
                                    "RIPRISTINA PREDEFINITO",
                                    style: TextStyle(color: Color(0xFFFF4D4D), fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        NeonButton(
                          text: 'GESTIONE COOKIE',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CookieScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                        NeonButton(
                          text: 'GESTIONE LUOGHI',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LocationScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        NeonButton(
                          text: 'SALVA CONFIGURAZIONE',
                          baseColor: const Color(0xFF00F2FF),
                          onPressed: _saveAndExit,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
