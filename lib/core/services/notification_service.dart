import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'fcm_token_datasource.dart';

/// Callback when a notification is tapped (background or terminated).
typedef MessageTapHandler = void Function(Map<String, dynamic> data);

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'chat_messages';
  static const _channelName = 'Chat Messages';
  static const _channelDescription = 'Notifications for new chat messages';

  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _foregroundSub;
  static StreamSubscription<RemoteMessage>? _tapSub;

  static MessageTapHandler? _tapHandler;

  static String? _currentUserId;
  static FcmTokenDataSource? _tokenDataSource;

  /// Request notification permissions and initialise local notifications.
  /// Call once at app startup.
  static Future<void> init() async {
    // Initialize timezones
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('[NotificationService] Failed to set local timezone: $e');
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
      '[NotificationService] Permission: ${settings.authorizationStatus}',
    );

    // --- Initialise flutter_local_notifications ---
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      // Request iOS local notification permissions
      if (Platform.isIOS) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }

      // Create the Android notification channel (required for Android 8.0+)
      if (Platform.isAndroid) {
        final androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Local notifications init failed: $e');
    }
  }

  /// Set handler for notification taps (e.g., navigate to chat).
  static void setMessageTapHandler(MessageTapHandler handler) {
    _tapHandler = handler;
  }

  /// Call when user authenticates. Saves FCM token and sets up listeners.
  static Future<void> onUserAuthenticated(
    String userId,
    FcmTokenDataSource tokenDataSource,
  ) async {
    _currentUserId = userId;
    _tokenDataSource = tokenDataSource;

    // Cancel existing subscriptions before creating new ones (prevents leaks on re-login)
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _foregroundSub?.cancel();
    _foregroundSub = null;
    await _tapSub?.cancel();
    _tapSub = null;

    // Save current token
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[NotificationService] Saving FCM token for user $userId');
        await tokenDataSource.saveToken(userId, token);
      }
    } catch (e) {
      debugPrint('[NotificationService] Error saving FCM token: $e');
    }

    // Listen for token refresh
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[NotificationService] Token refreshed, saving...');
      try {
        await tokenDataSource.saveToken(userId, newToken);
      } catch (e) {
        debugPrint('[NotificationService] Error saving refreshed token: $e');
      }
    });

    // Listen for foreground messages — show a local notification banner
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[NotificationService] Foreground message: '
        '${message.notification?.title}',
      );
      _showLocalNotification(message);
    });

    // Listen for notification taps (background state)
    _tapSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[NotificationService] Notification tap: ${message.data}');
      _tapHandler?.call(message.data);
    });

    // Check if app was opened from a terminated-state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '[NotificationService] Opened from terminated: '
        '${initialMessage.data}',
      );
      _tapHandler?.call(initialMessage.data);
    }
  }

  /// Call on logout. Deletes FCM token from Firestore and cleans up listeners.
  static Future<void> onUserLogout() async {
    if (_currentUserId != null && _tokenDataSource != null) {
      debugPrint(
        '[NotificationService] Deleting FCM token for user $_currentUserId',
      );
      try {
        await _tokenDataSource!.deleteToken(_currentUserId!);
      } catch (e) {
        debugPrint('[NotificationService] Error deleting FCM token: $e');
      }
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _foregroundSub?.cancel();
    _foregroundSub = null;
    await _tapSub?.cancel();
    _tapSub = null;

    _tapHandler = null;
    _currentUserId = null;
    _tokenDataSource = null;
  }

  static Future<String?> getToken() => _messaging.getToken();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
  }) async {
    try {
      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) return;

      const androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for upcoming tasks',
        importance: Importance.high,
        priority: Priority.high,
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      // Use zonedSchedule for modern flutter_local_notifications
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        payload: data != null ? jsonEncode(data) : null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('[NotificationService] Scheduled reminder for $scheduledDate');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling reminder: $e');
    }
  }

  static Future<void> cancelReminder(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Display a heads-up notification banner via flutter_local_notifications.
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title == null && body == null) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      final notificationId = message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch % 0x7FFFFFFF;

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('[NotificationService] Error showing notification: $e');
    }
  }

  /// Called when the user taps a local notification banner.
  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final data = Map<String, dynamic>.from(decoded);
      _tapHandler?.call(data);
    } catch (e) {
      debugPrint('[NotificationService] Error decoding notification tap: $e');
    }
  }
}
