import 'package:flutter/widgets.dart';

import 'bootstrap.dart';
import 'notifications/push_background_registration_stub.dart'
    if (dart.library.io) 'notifications/push_background_registration_io.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerPushBackgroundHandler();
  bootstrap();
}
