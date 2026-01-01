class AuthService {
  bool login(String email, String password) {
    return email.isNotEmpty && password.isNotEmpty;
  }

  bool register(String name, String email, String password) {
    return name.isNotEmpty && email.isNotEmpty && password.isNotEmpty;
  }
}
