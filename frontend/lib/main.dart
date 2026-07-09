import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/apps/router.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/newfeed/providers/feed_provider.dart';
import 'package:frontend/features/newfeed/providers/story_provider.dart';
import 'package:frontend/features/profile/providers/profile_provider.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'services/call_notification_service.dart';
import 'services/message_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Web không có background isolate — bỏ qua hoàn toàn.
  if (kIsWeb) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.data['type'] == 'incoming_call') {
    await CallNotificationService.showIncomingCall(message.data);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android-only ImagePicker tuning — không gọi trên web/desktop/iOS.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final imagePickerPlatform = ImagePickerPlatform.instance;
    if (imagePickerPlatform is ImagePickerAndroid) {
      imagePickerPlatform.useAndroidPhotoPicker = true;
    }
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // dotenv chỉ đọc được file `.env` đã bundle trong assets/ trên mobile/desktop.
  // Trên web dùng --dart-define=KEY=VALUE cho các biến môi trường.
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('[dotenv] could not load .env: $e');
    }
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }
  await CallNotificationService.initialize();
  await MessageNotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const TriChatApp(),
    ),
  );
}

class TriChatApp extends StatelessWidget {
  const TriChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createRouter();
    return ValueListenableBuilder(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp.router(
          title: 'TriChat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: router,
          locale: Locale(locale),
        );
      },
    );
  }
}

/// Trên mobile (Android) `image_picker_android` được dùng. Trên web các
/// lớp này vẫn tồn tại qua package, chỉ là chúng ta không bao giờ chạm vào
/// (đã guard bằng `kIsWeb`), nên import giữ nguyên nhưng sử dụng bị loại bỏ.

// Backward compat alias — một số nơi có thể tham chiếu MyApp
// ignore: camel_case_types
typedef MyApp = TriChatApp;
