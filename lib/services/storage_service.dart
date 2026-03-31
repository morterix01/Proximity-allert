import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String keyEmail = 'google_email';
  static const String keyNtfy = 'ntfy_topic';
  static const String keyCustomAudio = 'custom_audio';
  static const String keyLocations = 'locations';
  static const String keyCookies = 'google_cookies';
  static const String keyMonitoring = 'is_monitoring';

  late SharedPreferences prefs;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  String get email => prefs.getString(keyEmail) ?? '';
  Future<void> setEmail(String value) => prefs.setString(keyEmail, value);

  String get ntfyTopic => prefs.getString(keyNtfy) ?? 'proximity_alert_test';
  Future<void> setNtfyTopic(String value) => prefs.setString(keyNtfy, value);

  bool get isCustomAudio => prefs.getBool(keyCustomAudio) ?? false;
  Future<void> setCustomAudio(bool value) => prefs.setBool(keyCustomAudio, value);

  String get cookies => prefs.getString(keyCookies) ?? '';
  Future<void> setCookies(String value) => prefs.setString(keyCookies, value);

  bool get isMonitoring => prefs.getBool(keyMonitoring) ?? false;
  Future<void> setMonitoring(bool value) => prefs.setBool(keyMonitoring, value);

  List<MonitoredLocation> getLocations() {
    String? jsonStr = prefs.getString(keyLocations);
    if (jsonStr == null) return [];
    try {
      List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => MonitoredLocation.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocations(List<MonitoredLocation> locs) async {
    List<Map<String, dynamic>> list = locs.map((e) => e.toJson()).toList();
    await prefs.setString(keyLocations, jsonEncode(list));
  }
}
