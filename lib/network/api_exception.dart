class ClientErrorException implements Exception {
  final dynamic error;
  ClientErrorException({this.error});
}

class ServerErrorException implements Exception {
  final dynamic error;
  ServerErrorException({this.error});
}

class ConnectionException implements Exception {}

class UnknownException implements Exception {}
