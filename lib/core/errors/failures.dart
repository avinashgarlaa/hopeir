// core/errors/failure.dart

abstract class Failure {
  final String message;

  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}

class UnknownFailure extends Failure {
  UnknownFailure(super.message);
}
