import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../models/child_profile.dart';
import '../utils/constants.dart';
import 'local_profile_storage.dart';

abstract interface class AuthGateway {
  Future<void> ensureGoogleSignInInitialized();
  Stream<GoogleSignInAccount?> get onGoogleUserChanged;
  Future<String?> processGoogleUser(GoogleSignInAccount googleUser);
  Future<String?> login(String email, String password);
  Future<String?> loginWithGoogle();
  Future<void> logout();
  Future<String?> getUserRole();
  Future<bool> forgotPassword(String email);
}

class AuthService implements AuthGateway {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  static String get baseUrl {
    final configured = AppConstants.apiBaseUrl.trim();
    if (configured.isNotEmpty) {
      return '${configured.replaceFirst(RegExp(r'/$'), '')}/api/auth';
    }
    return kIsWeb
        ? 'http://localhost:8080/api/auth'
        : 'http://10.0.2.2:8080/api/auth';
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleInitialization;

  @override
  Future<void> ensureGoogleSignInInitialized() {
    return _googleInitialization ??= _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        clientId:
            '924493667390-cqn55fuer1la0p0vqsvotmubvtsbb7ic.apps.googleusercontent.com',
      );
    } catch (_) {
      // The web plugin can already be initialized after a hot reload.
    }
  }

  Future<bool> register(
    String fullName,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'FullName': fullName,
          'Email': email,
          'Password': password,
          'Role': role,
        }),
      );

      if (response.statusCode == 200) {
        final loginError = await login(email, password);
        return loginError == null;
      }
      throw AuthServiceException(_registrationError(response));
    } catch (e) {
      if (e is AuthServiceException) {
        rethrow;
      }
      debugPrint('Register error: $e');
      return false;
    }
  }

  String _registrationError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final message = data is Map<String, dynamic>
          ? data['message']?.toString()
          : null;
      if (message == 'Email is already in use.') {
        return 'Email này đã được sử dụng. Hãy đăng nhập hoặc dùng email khác.';
      }
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Fall through to the status-based message.
    }
    return 'Đăng ký thất bại (mã ${response.statusCode}). Vui lòng kiểm tra lại thông tin.';
  }

  @override
  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Email': email, 'Password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        await _restoreBasicChildProfileIfMissing(data);
        return null;
      }
      return data['message'] ?? 'Đăng nhập thất bại.';
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
      return 'Lỗi kết nối đến máy chủ.';
    }
  }

  @override
  Stream<GoogleSignInAccount?> get onGoogleUserChanged {
    return _googleSignIn.authenticationEvents.map((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        return event.user;
      }
      return null;
    });
  }

  @override
  Future<String?> processGoogleUser(GoogleSignInAccount googleUser) async {
    try {
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) return 'Không thể lấy token từ Google.';

      final response = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'IdToken': idToken, 'Role': 'Child'}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        await _restoreBasicChildProfileIfMissing(data);
        return null;
      }
      return data['message'] ?? 'Đăng nhập Google thất bại.';
    } catch (e) {
      if (kDebugMode) print('Process Google user error: $e');
      return 'Lỗi kết nối đến máy chủ.';
    }
  }

  @override
  Future<String?> loginWithGoogle() async {
    try {
      await ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      return await processGoogleUser(googleUser);
    } catch (e) {
      if (kDebugMode) print('Google login error: $e');
      return 'Lỗi đăng nhập Google: $e';
    }
  }

  @override
  Future<void> logout() async {
    try {
      await ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google signOut error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> _restoreBasicChildProfileIfMissing(
    Map<String, dynamic> authData,
  ) async {
    if (authData['role']?.toString() != 'Child') {
      return;
    }

    const profileStorage = LocalProfileStorage();
    if (await profileStorage.hasProfile()) {
      return;
    }

    final fullName = authData['fullName']?.toString().trim();
    await profileStorage.saveProfile(
      ChildProfile(
        childName: fullName == null || fullName.isEmpty ? 'Bé' : fullName,
        age: '',
        gender: '',
        learningGoals: const [],
        acceptedTerms: false,
        completedAt: DateTime.now(),
      ),
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;
    return !JwtDecoder.isExpired(token);
  }

  @override
  Future<String?> getUserRole() async {
    final token = await getToken();
    if (token == null) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    var roleClaim = decodedToken['role'] ??
        decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
    
    if (roleClaim is List) {
      return roleClaim.isNotEmpty ? roleClaim.first.toString() : null;
    }
    return roleClaim?.toString();
  }

  Future<int?> getUserId() async {
    final claims = await _getTokenClaims();
    final value = claims?['UserId'] ?? claims?['sub'];
    return value is int ? value : int.tryParse(value?.toString() ?? '');
  }

  Future<String?> getUserEmail() async {
    final claims = await _getTokenClaims();
    final value =
        claims?['email'] ??
        claims?['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'];
    final email = value?.toString().trim();
    return email == null || email.isEmpty ? null : email;
  }

  Future<Map<String, dynamic>?> _getTokenClaims() async {
    final token = await getToken();
    if (token == null || JwtDecoder.isExpired(token)) {
      return null;
    }
    return JwtDecoder.decode(token);
  }

  @override
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Forgot password error: $e');
      }
      return false;
    }
  }
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
