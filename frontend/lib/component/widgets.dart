/// ════════════════════════════════════════════════════════════════
/// Barrel export cho tất cả shared widgets / components.
/// ════════════════════════════════════════════════════════════════
///
/// Import một dòng duy nhất:
///
/// ```dart
/// import 'package:frontend/component/widgets.dart';
/// ```
library;

export 'avatars.dart';
export 'buttons.dart';
export 'dialogs.dart';
export 'inputs.dart';
export 'states.dart';
export 'tri_app_bar.dart';

// Re-export các widget đã có sẵn (giữ để tương thích ngược)
export 'app_bar.dart';
export 'confirm_phone_sheet.dart';
export 'friend_search_appbar.dart';
export 'friend_search_page.dart';
export 'friend_search_screen.dart';
export 'loading_dialog.dart';
export 'ripple_aminimation.dart';
export 'success_dialog.dart';