import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔵 Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Messaging',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MessagingHomePage(),
    );
  }
}

class MessagingHomePage extends StatefulWidget {
  @override
  State<MessagingHomePage> createState() => _MessagingHomePageState();
}

class _MessagingHomePageState extends State<MessagingHomePage> {
  String? _fcmToken;
  String? _notificationMessage;

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Get FCM token
    final token = await messaging.getToken();
    print('🔑 FCM Token: $token');
    setState(() => _fcmToken = token);

    // Subscribe to topic
    await messaging.subscribeToTopic("messaging");

    // Foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final type = message.data['notificationType'] ?? 'regular';
      final body = message.notification?.body ?? 'No message body';

      setState(() => _notificationMessage = body);

      _showCustomDialog(type, body);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 Notification opened from background");
    });
  }

  void _showCustomDialog(String type, String body) {
    final isImportant = type == 'important';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isImportant ? "🚨 Important Notification" : "📩 Regular Notification"),
        content: Text(body),
        backgroundColor: isImportant ? Colors.red[100] : Colors.blue[100],
        actions: [
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Messaging')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("FCM Token:", style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(_fcmToken ?? "Loading token..."),
            SizedBox(height: 24),
            Text("Last Message:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_notificationMessage ?? "No messages yet."),
          ],
        ),
      ),
    );
  }
}
