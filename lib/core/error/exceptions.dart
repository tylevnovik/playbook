class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}
