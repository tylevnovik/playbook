import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class ApiFailure extends Failure {
  final int? statusCode;
  const ApiFailure(super.message, {this.statusCode});

  @override
  List<Object> get props => [message, if (statusCode != null) statusCode!];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class FileFailure extends Failure {
  const FileFailure(super.message);
}
