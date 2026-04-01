import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'google_location_service.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final StorageService storage = StorageService();
  await storage.init();

  final GoogleLocationService googleLocationService = GoogleLocationService();
  final audioPlayer = AudioPlayer();
  const distance = Distance();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Audio context for iOS background playback
  await audioPlayer.setAudioContext(AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {
        AVAudioSessionOptions.mixWithOthers,
        AVAudioSessionOptions.duckOthers,
      },
    ),
    android: const AudioContextAndroid(),
  ));

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initializationSettings =
      InitializationSettings(iOS: initializationSettingsDarwin);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const DarwinNotificationDetails iosNotificationDetails =
      DarwinNotificationDetails();
  const NotificationDetails notificationDetails =
      NotificationDetails(iOS: iosNotificationDetails);

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (!storage.isMonitoring) return;

    final people = await googleLocationService.getSharedPeople();
    final locations = storage.getLocations();

    bool foundClose = false;
    String matchedPerson = "";
    String matchedLoc = "";

    for (var person in people) {
      for (var loc in locations) {
        final dist = distance.as(
            LengthUnit.Meter,
            LatLng(person.latitude, person.longitude),
            LatLng(loc.lat, loc.lon));

        if (dist <= loc.radiusMeters) {
          foundClose = true;
          matchedPerson = person.fullName;
          matchedLoc = loc.name;
          break;
        }
      }
      if (foundClose) break;
    }

    if (foundClose) {
      await flutterLocalNotificationsPlugin.show(
        0,
        'Prossimità Rilevata!',
        '$matchedPerson è vicino a $matchedLoc',
        notificationDetails,
      );

      if (audioPlayer.state != PlayerState.playing) {
        await audioPlayer.play(AssetSource('audio/Star Labs alarm.mp3'),
            volume: 1.0);
        audioPlayer.setReleaseMode(ReleaseMode.loop);
      }

      try {
        final topic = storage.ntfyTopic;
        if (topic.isNotEmpty) {
          await http.post(Uri.parse('https://ntfy.sh/$topic'),
              body: '$matchedPerson è vicino a $matchedLoc',
              headers: {
                'Title': 'ALLARME PROSSIMITA',
                'Priority': 'urgent',
                'Tags': 'warning'
              });
        }
      } catch (_) {}
    } else {
      if (audioPlayer.state == PlayerState.playing) {
        await audioPlayer.stop();
      }
    }
  });

  service.on('stopService').listen((event) async {
    await audioPlayer.stop();
    await storage.setMonitoring(false);
    service.stopSelf();
  });
}

class AppBackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }
}
