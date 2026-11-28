import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../domain/entities/notification_permission.dart';
import '../../../domain/usecases/reminder_schedule.dart';
import 'reminder_notifications_data_source.dart';

/// Hiện thực [ReminderNotificationsDataSource] bằng
/// `flutter_local_notifications`.
///
/// Chỉ bật trên Android và iOS; ở web, máy tính và khi chạy test mọi hàm đều
/// không làm gì và quyền trả về [NotificationPermission.unsupported].
class LocalReminderNotifications implements ReminderNotificationsDataSource {
  LocalReminderNotifications();

  static const String _channelId = 'study_reminders';
  static const String _channelName = 'Nhắc nhở học tập';

  @override
  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  final StreamController<String> _taps = StreamController<String>.broadcast();
  FlutterLocalNotificationsPlugin? _plugin;
  Future<void>? _ready;

  /// Lần bấm thông báo chưa có ai nghe (ví dụ app vừa mở từ thông báo).
  String? _pending;

  Future<FlutterLocalNotificationsPlugin> _ensureReady() async {
    await (_ready ??= _initialize());
    return _plugin!;
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(_localLocation());
    final plugin = _plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Không hỏi quyền lúc mở app; chỉ hỏi khi người dùng tạo nhắc nhở.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _deliver(response.payload);
      },
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _deliver(launch!.notificationResponse?.payload);
    }
  }

  void _deliver(String? noteId) {
    if (noteId == null || noteId.isEmpty) return;
    if (_taps.hasListener) {
      _taps.add(noteId);
    } else {
      _pending = noteId;
    }
  }

  /// Gói `timezone` không tự biết múi giờ của máy; chọn vùng có độ lệch giờ
  /// trùng với máy, ưu tiên Việt Nam.
  static tz.Location _localLocation() {
    final offset = DateTime.now().timeZoneOffset;
    final vietnam = tz.getLocation('Asia/Ho_Chi_Minh');
    if (vietnam.currentTimeZone.offset == offset) return vietnam;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.currentTimeZone.offset == offset) return location;
    }
    return tz.UTC;
  }

  AndroidFlutterLocalNotificationsPlugin? _android(
    FlutterLocalNotificationsPlugin plugin,
  ) => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? _ios(
    FlutterLocalNotificationsPlugin plugin,
  ) => plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<NotificationPermission> checkPermission() async {
    if (!isSupported) return NotificationPermission.unsupported;
    final plugin = await _ensureReady();
    final enabled = Platform.isAndroid
        ? await _android(plugin)?.areNotificationsEnabled()
        : (await _ios(plugin)?.checkPermissions())?.isEnabled;
    return enabled ?? false
        ? NotificationPermission.granted
        : NotificationPermission.denied;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    if (!isSupported) return NotificationPermission.unsupported;
    final plugin = await _ensureReady();
    bool? granted;
    if (Platform.isAndroid) {
      final android = _android(plugin);
      granted = await android?.requestNotificationsPermission();
      // Android 14+ mặc định tắt báo thức đúng giờ; xin thêm để nhắc đúng phút.
      if ((granted ?? false) &&
          !(await android?.canScheduleExactNotifications() ?? true)) {
        await android?.requestExactAlarmsPermission();
      }
    } else {
      granted = await _ios(plugin)
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return granted ?? false
        ? NotificationPermission.granted
        : NotificationPermission.denied;
  }

  @override
  Future<void> openSettings() async {
    if (!isSupported) return;
    final plugin = await _ensureReady();
    if (Platform.isAndroid) {
      await _android(plugin)?.openAppNotificationSettings();
    } else {
      await _ios(plugin)?.openAppNotificationSettings();
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required ReminderMatch match,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!isSupported) return;
    final plugin = await _ensureReady();
    await plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Thông báo đến giờ ôn lại ghi chú',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: await _scheduleMode(plugin),
      title: title,
      body: body,
      payload: payload,
      matchDateTimeComponents: switch (match) {
        ReminderMatch.none => null,
        ReminderMatch.dailyTime => DateTimeComponents.time,
        ReminderMatch.weeklyDayAndTime => DateTimeComponents.dayOfWeekAndTime,
      },
    );
  }

  /// Báo đúng phút nếu được phép, nếu không thì để hệ điều hành báo gần đúng
  /// giờ (có thể trễ vài phút khi máy tiết kiệm pin).
  Future<AndroidScheduleMode> _scheduleMode(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    final exact = await _android(plugin)?.canScheduleExactNotifications();
    return exact ?? false
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<void> cancel(int id) async {
    if (!isSupported) return;
    final plugin = await _ensureReady();
    await plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAllPending() async {
    if (!isSupported) return;
    final plugin = await _ensureReady();
    await plugin.cancelAllPendingNotifications();
  }

  @override
  Stream<String> get openedNoteIds {
    if (!isSupported) return const Stream<String>.empty();
    // Khởi tạo sớm để đọc được thông báo đã mở app khi app đang đóng.
    unawaited(_ensureReady());
    return Stream<String>.multi((MultiStreamController<String> controller) {
      final pending = _pending;
      _pending = null;
      if (pending != null) controller.add(pending);
      final subscription = _taps.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> dispose() => _taps.close();
}
