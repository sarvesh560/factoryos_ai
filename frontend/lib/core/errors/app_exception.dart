/// Typed API and network errors for FactoryOS AI
class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'AppException($code, $statusCode): $message';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Unable to connect to FactoryOS backend services. Please verify Django is running on port 8000.',
    super.code = 'NETWORK_ERROR',
  });
}

class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code = 'SERVER_ERROR',
    super.statusCode,
    super.details,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Requested factory resource was not found.',
    super.code = 'NOT_FOUND',
    super.statusCode = 404,
  });
}
