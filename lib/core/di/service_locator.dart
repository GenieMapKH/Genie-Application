import '../network/api_client.dart';
import '../services/auth_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  
  factory ServiceLocator() {
    return _instance;
  }
  
  ServiceLocator._internal();

  AuthService authService = AuthService(createApiClient());
}

final locator = ServiceLocator();
