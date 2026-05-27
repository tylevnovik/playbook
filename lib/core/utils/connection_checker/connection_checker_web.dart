// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

class ConnectionChecker {
  static Future<bool> get isConnected async {
    return html.window.navigator.onLine ?? true;
  }

  static Stream<bool> get onConnectionChanged {
    final controller = StreamController<bool>.broadcast();

    // Send current status immediately
    Timer.run(() {
      controller.add(html.window.navigator.onLine ?? true);
    });

    html.window.onOnline.listen((_) => controller.add(true));
    html.window.onOffline.listen((_) => controller.add(false));

    return controller.stream;
  }
}
