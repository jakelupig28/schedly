import 'dart:convert';
import 'dart:io';

class AuthResult {
  final bool success;
  final String? uid;
  final String? email;
  final String? idToken;
  final String? errorMessage;

  AuthResult({
    required this.success,
    this.uid,
    this.email,
    this.idToken,
    this.errorMessage,
  });
}

class AuthService {
  static const String _apiKey = "AIzaSyDyUpEJhmf-KjxiGI4j_AFQasJRrHxXKT8";

  /// Sign in with Email and Password using official Firebase Auth Identity Toolkit API
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey",
      );

      final client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final body = json.encode({
        "email": email.trim(),
        "password": password,
        "returnSecureToken": true,
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      final data = json.decode(responseBody);

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          uid: data['localId'],
          email: data['email'],
          idToken: data['idToken'],
        );
      } else {
        final error = data['error']?['message'] ?? 'UNKNOWN_ERROR';
        String userFriendlyMsg = _mapAuthError(error);
        return AuthResult(
          success: false,
          errorMessage: userFriendlyMsg,
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: "Network error: Unable to connect to Firebase. Please check your internet connection.",
      );
    }
  }

  /// Register new user with Email and Password
  static Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey",
      );

      final client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final body = json.encode({
        "email": email.trim(),
        "password": password,
        "returnSecureToken": true,
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      final data = json.decode(responseBody);

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          uid: data['localId'],
          email: data['email'],
          idToken: data['idToken'],
        );
      } else {
        final error = data['error']?['message'] ?? 'UNKNOWN_ERROR';
        String userFriendlyMsg = _mapAuthError(error);
        return AuthResult(
          success: false,
          errorMessage: userFriendlyMsg,
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: "Network error: Unable to connect to Firebase. Please check your internet connection.",
      );
    }
  }

  /// Send password reset link to user's email
  static Future<bool> sendPasswordReset(String email) async {
    try {
      final uri = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$_apiKey",
      );

      final client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final body = json.encode({
        "requestType": "PASSWORD_RESET",
        "email": email.trim(),
      });

      request.write(body);
      final response = await request.close();
      await response.drain();
      client.close();

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static String _mapAuthError(String code) {
    if (code.contains('EMAIL_NOT_FOUND') || code.contains('USER_NOT_FOUND')) {
      return "Account not found. This account does not exist or was deleted in Firebase.";
    }
    if (code.contains('INVALID_PASSWORD') || code.contains('INVALID_LOGIN_CREDENTIALS')) {
      return "Incorrect email or password. Please check your credentials.";
    }
    if (code.contains('USER_DISABLED')) {
      return "This account has been disabled by the administrator.";
    }
    if (code.contains('EMAIL_EXISTS')) {
      return "This email is already registered. Please log in instead.";
    }
    if (code.contains('OPERATION_NOT_ALLOWED')) {
      return "Email/password sign-in is not enabled in Firebase Authentication console.";
    }
    if (code.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
      return "Access temporarily blocked due to many failed attempts. Try again later.";
    }
    if (code.contains('WEAK_PASSWORD')) {
      return "Password is too weak. Please use at least 6 characters.";
    }
    if (code.contains('INVALID_EMAIL')) {
      return "Please enter a valid email address.";
    }
    return "Authentication failed: $code";
  }
}
