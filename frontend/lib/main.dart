import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/apps/router.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/newfeed/providers/feed_provider.dart';
import 'package:frontend/features/newfeed/providers/story_provider.dart';
import 'package:frontend/features/profile/providers/profile_provider.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'services/call_notification_service.dart';
import 'services/message_notification_service.dart';

import 'main_stub.dart' if (dart.library.io) 'main_mobile.dart' as platform_main;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform-specific initialization
  await platform_main.initPlatform();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // dotenv chỉ đọc được file `.env` đã bundle trong assets/ trên mobile/desktop.
  // Trên web vẫn load được vì file đã đăng ký trong pubspec.yaml `assets:` —
  // chỉ cần đảm bảo dev/prod server không ignore dotfile (đã verify với
  // Flutter web dev server). Nếu sau này deploy lên server khác mà `.env`
  // bị ignore, hãy đổi tên thành `env` và cập nhật `fileName` + `assets:`.
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Web server có thể chặn file bắt đầu bằng `.` — fallback im lặng để
    // ApiConfig rơi về `--dart-define` hoặc `_webOrigin()`.
  }

  if (!kIsWeb) {
    // Background handler chỉ trên mobile
    platform_main.initBackgroundHandler();
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
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return ValueListenableBuilder<String>(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp.router(
              title: 'TriChat',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              routerConfig: router,
              locale: Locale(locale),
            );
          },
        );
      },
    );
  }
}

// Backward compat alias
typedef MyApp = TriChatApp;