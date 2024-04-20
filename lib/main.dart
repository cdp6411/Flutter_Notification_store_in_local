import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notification_demo/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();

  // Fetch and decode data
  final String? notificationString = preferences.getString('list');

  final List<NotificationModel> myList =
      NotificationModel.decode(notificationString!);

  // Add into list
  myList.add(NotificationModel(
      title: message.notification!.title, body: message.notification!.body));

  // Encode and store data in SharedPreferences
  final String encodedData = NotificationModel.encode(myList);

  await preferences.setString('list', encodedData);
}

SharedPreferences? preferences;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  preferences = await SharedPreferences.getInstance();
  FirebaseMessaging.onMessage.listen((event) async {
    // Fetch and decode data
    final String notificationString = preferences!.getString('list') ?? '';

    final List<NotificationModel> myList = notificationString.isEmpty
        ? []
        : NotificationModel.decode(notificationString);

    // Add into list
    myList.add(NotificationModel(
        title: event.notification!.title, body: event.notification!.body));
    navigatorKey.currentContext!
        .read<NotificationProvider>()
        .setNotificationModel(myList);
    // Encode and store data in SharedPreferences
    final String encodedData = NotificationModel.encode(myList);

    await preferences!.setString('list', encodedData);
  });
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (create) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    FirebaseMessaging.instance.getToken().then((value) {
      String? token = value;
      log(token!, name: "FB_TOKEN");
    });
    // Fetch and decode data
    Future.delayed(
      Duration.zero,
      () {
        final String notificationString = preferences!.getString('list') ?? '';

        final List<NotificationModel> myList = notificationString.isEmpty
            ? []
            : NotificationModel.decode(notificationString);
        context.read<NotificationProvider>().setNotificationModel(myList);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      preferences?.reload().then((value) {
        final String notificationString = preferences!.getString('list') ?? '';

        final List<NotificationModel> myList = notificationString.isEmpty
            ? []
            : NotificationModel.decode(notificationString);
        context.read<NotificationProvider>().setNotificationModel(myList);
      });
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    final noProvider = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: noProvider.notificationList!.isNotEmpty
          ? ListView.builder(
              itemCount: noProvider.notificationList!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade400,
                      child: Text((index + 1).toString())),
                  title: Text(noProvider.notificationList![index]!.title!),
                  subtitle: Text(noProvider.notificationList![index]!.body!),
                );
              },
            )
          : const Center(
              child: Text('No notification'),
            ),
    );
  }
}

class NotificationModel {
  final String? title;
  final String? body;
  NotificationModel({
    this.title,
    this.body,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> jsonData) {
    return NotificationModel(title: jsonData['title'], body: jsonData['body']);
  }

  static Map<String, dynamic> toMap(NotificationModel list) => {
        'title': list.title,
        'body': list.body,
      };

  static String encode(List<NotificationModel> musics) => json.encode(
        musics
            .map<Map<String, dynamic>>(
                (music) => NotificationModel.toMap(music))
            .toList(),
      );

  static List<NotificationModel> decode(String musics) =>
      (json.decode(musics) as List<dynamic>)
          .map<NotificationModel>((item) => NotificationModel.fromJson(item))
          .toList();
}
