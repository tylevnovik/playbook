import 'dart:async';
import 'dart:io';

class ConnectionChecker {
  static Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('1.1.1.1').timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Stream<bool> get onConnectionChanged {
    final controller = StreamController<bool>.broadcast();
    Timer? timer;
    
    void check() async {
      final connected = await isConnected;
      if (!controller.isClosed) {
        controller.add(connected);
      }
    }

    controller.onListen = () {
      check();
      timer = Timer.periodic(const Duration(seconds: 10), (_) => check());
    };

    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }
}
