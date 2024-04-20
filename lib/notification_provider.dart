import 'package:flutter/material.dart';
import 'package:notification_demo/main.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel?>? _notificationList = [];
  List<NotificationModel?>? get notificationList => _notificationList;

  void setNotificationModel(List<NotificationModel?> val) {
    _notificationList = val;
    notifyListeners();
  }
}
