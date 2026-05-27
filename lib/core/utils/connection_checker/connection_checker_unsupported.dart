class ConnectionChecker {
  static Future<bool> get isConnected async => true;
  static Stream<bool> get onConnectionChanged => Stream.value(true);
}
