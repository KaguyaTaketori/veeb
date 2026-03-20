import 'dart:async';

enum AuthEvent { logout }

class AuthEventBus {
  AuthEventBus._();
  static final AuthEventBus instance = AuthEventBus._();

  final _controller = StreamController<AuthEvent>.broadcast();
  Stream<AuthEvent> get stream => _controller.stream;

  void logout() => _controller.add(AuthEvent.logout);
}