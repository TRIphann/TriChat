// Mobile-specific initialization
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:frontend/services/call_notification_service.dart';
import 'package:frontend/firebase_options.dart';

Future<void> initPlatform() async {
  // Android-only ImagePicker tuning
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
}

void initBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
}

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.data['type'] == 'incoming_call') {
    await CallNotificationService.showIncomingCall(message.data);
  }
}
