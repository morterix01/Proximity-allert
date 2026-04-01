import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/person.dart';
import 'storage_service.dart';

class GoogleLocationService {
  final StorageService storage = StorageService();

  Future<List<Person>> getSharedPeople() async {
    String cookies = storage.cookies;
    if (cookies.isEmpty) return [];

    final url = Uri.parse('https://www.google.com/maps/rpc/locationsharing/read?authuser=0&hl=en&gl=us&pb=!1m7!8m6!1m3!1i14!2i8413!3i5385!2i6!3x4095!2m3!1e0!2sm!3i407105169!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e1!5m4!1e4!8m2!1e0!1e1!6m9!1e12!2i2!26m1!4b1!30m1!1f1.3953487873077393!39b1!44e1!50e0!23i4111425');

    final response = await http.get(url, headers: {
      'cookie': cookies,
      'user-agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
    });

    if (response.statusCode != 200) return [];

    final bodyStr = response.body;
    int firstQuote = bodyStr.indexOf("'");
    if (firstQuote == -1) return [];

    String jsonStr = bodyStr.substring(firstQuote + 1);
    
    // The response actually ends with a quote or newline depending on formatting.
    // Try to parse the json up to the end.
    if (jsonStr.endsWith("'")) {
      jsonStr = jsonStr.substring(0, jsonStr.length - 1);
    }

    try {
      List<dynamic> data = jsonDecode(jsonStr);
      if (data.length > 6 && data[6] == 'GgA=') {
        debugPrint("Google Alert: Not authenticated anymore (GgA)");
        return [];
      }

      if (data.isEmpty || data[0] == null) {
        debugPrint("Google Alert: Response data[0] is null/empty");
        return [];
      }

      List<dynamic> sharedPeopleList = data[0];
      List<Person> people = [];
      debugPrint("Found ${sharedPeopleList.length} shared people in raw data");

      for (var entry in sharedPeopleList) {
        try {
          if (entry.length < 7 || entry[6] == null) continue;
          
          final id = entry[6][0].toString();
          final avatarUrl = entry[6][1].toString();
          final fullName = entry[6][2].toString();
          
          // Location info usually at index 1
          if (entry[1] == null || entry[1].length < 3) continue;
          
          // entry[1][1] is [unknown, lon, lat, ...]
          if (entry[1][1] == null || entry[1][1].length < 3) continue;
          
          final lat = double.tryParse(entry[1][1][2].toString()) ?? 0.0;
          final lon = double.tryParse(entry[1][1][1].toString()) ?? 0.0;
          final timestamp = int.tryParse(entry[1][2].toString()) ?? 0;
          
          double accuracy = 0.0;
          if (entry[1].length > 3 && entry[1][3] != null) {
              accuracy = double.tryParse(entry[1][3].toString()) ?? 0.0;
          }
          String address = "";
          if (entry[1].length > 4 && entry[1][4] != null) {
              address = entry[1][4].toString();
          }

          int battery = 0;
          bool isCharging = false;
          if (entry.length > 13 && entry[13] != null && entry[13].length > 1) {
             battery = int.tryParse(entry[13][1].toString()) ?? 0;
             isCharging = entry[13][0] == 1;
          }

          debugPrint("Parsed person: $fullName at $lat, $lon");

          people.add(Person(
            id: id,
            fullName: fullName,
            avatarUrl: avatarUrl,
            latitude: lat,
            longitude: lon,
            accuracy: accuracy,
            address: address,
            batteryLevel: battery,
            isCharging: isCharging,
            timestampMs: timestamp,
          ));
        } catch (innerE) {
          debugPrint("Failed parsing individual entry: $innerE");
        }
      }
      return people;
    } catch (e) {
      debugPrint("Error parsing JSON overall: $e");
      return [];
    }
  }
}
