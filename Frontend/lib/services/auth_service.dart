import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/auth';
    }
    return 'http://10.0.2.2:8080/api/auth';
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  Future<void> ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      try {
        await _googleSignIn.initialize(
          clientId: '924493667390-cqn55fuer1la0p0vqsvotmubvtsbb7ic.apps.googleusercontent.com', 
        );
      } catch (e) {
        // Ignore initialization error on web during hot reload
      }
      _isGoogleSignInInitialized = true;
    }
  }

  Future<bool> register(String fullName, String email, String password, String role) async {
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
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email': email,
          'Password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        return null; // Success
      }
      return data['message'] ?? 'Đăng nhập thất bại.';
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
      return 'Lỗi kết nối đến máy chủ.';
    }
  }

  Stream<GoogleSignInAccount?> get onGoogleUserChanged {
    return _googleSignIn.authenticationEvents.map((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        return event.user;
      }
      return null;
    });
  }

  Future<String?> processGoogleUser(GoogleSignInAccount googleUser) async {
    try {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) return 'Không thể lấy token từ Google.';

      final response = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'IdToken': idToken,
          'Role': 'Child',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        return null; // Success
      }
      return data['message'] ?? 'Đăng nhập Google thất bại.';
    } catch (e) {
      if (kDebugMode) print('Process Google user error: $e');
      return 'Lỗi kết nối đến máy chủ.';
    }
  }

  Future<String?> loginWithGoogle() async {
    try {
      await ensureGoogleSignInInitialized();
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) return 'Đã hủy đăng nhập Google.';
      return await processGoogleUser(googleUser);
    } catch (e) {
      if (kDebugMode) print('Google login error: $e');
      return 'Lỗi đăng nhập Google: $e';
    }
  }

  Future<void> logout() async {
    try {
      await ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Google signOut error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
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

  Future<String?> getUserRole() async {
    final token = await getToken();
    if (token == null) return null;
    
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    // ASP.NET Core usually puts role in 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'
    // or just 'role'.
    return decodedToken['role'] ?? decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
  }

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
        print('Forgot password error: $e');
      }
      return false;
    }
  }
}
