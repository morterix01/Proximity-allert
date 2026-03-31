import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/storage_service.dart';
import '../widgets/neon_button.dart';

class CookieScreen extends StatefulWidget {
  const CookieScreen({super.key});

  @override
  State<CookieScreen> createState() => _CookieScreenState();
}

class _CookieScreenState extends State<CookieScreen> {
  final StorageService _storage = StorageService();
  WebViewController? _controller;
  bool _isWebViewOpen = false;
  String _status = "STATUS: Pronto";
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _status = "Pagina caricata. Fai il login.";
            });
          },
        ),
      );
    }
  }

  void _loginOnline() {
    setState(() {
      _isWebViewOpen = true;
      _status = kIsWeb ? "Non supportato su Web" : "Inizializzazione WebView...";
    });
    if (kIsWeb) return;
    _controller?.loadRequest(Uri.parse('https://accounts.google.com/'));
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isWebViewOpen) {
        timer.cancel();
        return;
      }

      if (_controller == null) return;
      final String cookiesString =
          await _controller!.runJavaScriptReturningResult('document.cookie') as String;

      String rawCookies = cookiesString.replaceAll('"', '');
      bool hasSid = rawCookies.contains('SID=');
      String formattedCookies = rawCookies;

      if (hasSid && mounted) {
        timer.cancel();
        await _storage.setCookies(formattedCookies);
        setState(() {
          _status = "Cookie salvati! Torno indietro...";
          _isWebViewOpen = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isWebViewOpen) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_status,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: kIsWeb 
                    ? const Center(
                        child: Text("La WebView nativa non è supportata nell'anteprima web.", textAlign: TextAlign.center,)
                      )
                    : WebViewWidget(controller: _controller!),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isWebViewOpen = false;
                    _status = "Login Annullato.";
                  });
                },
                child: const Text("Annulla"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'COOKIE HUB',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              NeonButton(
                text: 'SIGN IN NOW (AUTO)',
                onPressed: _loginOnline,
              ),
              const SizedBox(height: 20),
              Text(
                _status,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
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
