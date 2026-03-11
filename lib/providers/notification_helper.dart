import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('notif');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notif init error: $e');
    }
  }

  Future<void> showIncomeNotification({
    required String category,
    required String amount,
  }) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'income_channel',
        'Pemasukan',
        channelDescription: 'Notifikasi saat ada pemasukan baru',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF00E676),
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
        '💰 Pemasukan Dicatat!',
        '$category  •  +$amount',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Notif income error: $e');
    }
  }

  Future<void> showExpenseNotification({
    required String category,
    required String amount,
  }) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'expense_channel',
        'Pengeluaran',
        channelDescription: 'Notifikasi saat ada pengeluaran baru',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFFFF5252),
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
        '🛒 Pengeluaran Dicatat!',
        '$category  •  -$amount',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Notif expense error: $e');
    }
  }
}