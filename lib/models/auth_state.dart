enum AuthNavigationState {
  registrationSuccess,
  welcomeBack,
  main,
}

class AuthStateManager {
  static AuthNavigationState? _currentState;
  
  static void setRegistrationSuccess() {
    _currentState = AuthNavigationState.registrationSuccess;
  }
  
  static void setWelcomeBack() {
    _currentState = AuthNavigationState.welcomeBack;
  }
  
  static void setMain() {
    _currentState = AuthNavigationState.main;
  }
  
  static void clearState() {
    _currentState = null;
  }
  
  static AuthNavigationState? getCurrentState() {
    return _currentState;
  }
  
  static bool get showRegistrationSuccess => _currentState == AuthNavigationState.registrationSuccess;
  static bool get showWelcomeBack => _currentState == AuthNavigationState.welcomeBack;
}
