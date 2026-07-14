import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import 'auth_service.dart';

class PremiumService {
  PremiumService({AuthService? authService, http.Client? client})
    : _authService = authService ?? AuthService(),
      _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  String get _baseUrl {
    final value = AppConstants.apiBaseUrl.trim();
    if (value.isNotEmpty) return value.replaceFirst(RegExp(r'/$'), '');
    return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }

  Future<PremiumStatus> getStatus() async {
    final userId = await _requiredUserId();
    final headers = await _authHeaders();
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/premium/status/$userId'),
      headers: headers,
    );
    return PremiumStatus.fromJson(_decode(response));
  }

  Future<PremiumStatus> redeemCode(String code) async {
    final userId = await _requiredUserId();
    final email = await _authService.getUserEmail();
    final headers = await _authHeaders(json: true);
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/premium/redeem-code'),
      headers: headers,
      body: jsonEncode({'userId': userId, 'email': email, 'code': code}),
    );
    return PremiumStatus.fromJson(_decode(response));
  }

  Future<List<PremiumPlan>> getPlans() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/premium/plans'),
    );
    Object? payload;
    try {
      payload = jsonDecode(response.body);
    } catch (_) {
      payload = null;
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload is! List) {
      throw const PremiumServiceException('Không tải được các gói Premium.');
    }
    return payload
        .whereType<Map<String, dynamic>>()
        .map(PremiumPlan.fromJson)
        .toList(growable: false);
  }

  Future<PremiumPayment> createPayment(String planCode) async {
    final userId = await _requiredUserId();
    final email = await _authService.getUserEmail();
    final headers = await _authHeaders(json: true);
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/premium/payments'),
      headers: headers,
      body: jsonEncode({
        'userId': userId,
        'email': email,
        'planCode': planCode,
      }),
    );
    return PremiumPayment.fromJson(_decode(response));
  }

  Future<PremiumStatus> confirmPayment(int orderCode) async {
    final userId = await _requiredUserId();
    final headers = await _authHeaders(json: true);
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/premium/payments/$orderCode/confirm'),
      headers: headers,
      body: jsonEncode({'userId': userId}),
    );
    return PremiumStatus.fromJson(_decode(response));
  }

  Future<int> _requiredUserId() async {
    final userId = await _authService.getUserId();
    if (userId == null) {
      throw const PremiumServiceException('Bạn cần đăng nhập trước.');
    }
    return userId;
  }

  Future<Map<String, String>> _authHeaders({bool json = false}) async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw const PremiumServiceException('Phiên đăng nhập đã hết hạn.');
    }
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    Object? payload;
    try {
      payload = jsonDecode(response.body);
    } catch (_) {
      payload = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic>
          ? payload['message']?.toString()
          : null;
      throw PremiumServiceException(
        message ?? 'Premium API returned ${response.statusCode}.',
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw const PremiumServiceException('Invalid Premium response.');
    }
    return payload;
  }
}

class PremiumStatus {
  const PremiumStatus({
    required this.hasPremium,
    this.planCode,
    this.activeUntil,
  });
  factory PremiumStatus.fromJson(Map<String, dynamic> json) => PremiumStatus(
    hasPremium: json['hasPremium'] == true,
    planCode: json['planCode']?.toString(),
    activeUntil: DateTime.tryParse(json['activeUntil']?.toString() ?? ''),
  );
  final bool hasPremium;
  final String? planCode;
  final DateTime? activeUntil;
}

class PremiumPlan {
  const PremiumPlan({
    required this.planCode,
    required this.name,
    required this.amount,
    required this.currency,
  });
  factory PremiumPlan.fromJson(Map<String, dynamic> json) => PremiumPlan(
    planCode: json['planCode']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    amount: json['amount'] is int
        ? json['amount'] as int
        : int.tryParse('${json['amount']}') ?? 0,
    currency: json['currency']?.toString() ?? 'VND',
  );
  final String planCode;
  final String name;
  final int amount;
  final String currency;
}

class PremiumPayment {
  const PremiumPayment({required this.orderCode, required this.checkoutUrl});
  factory PremiumPayment.fromJson(Map<String, dynamic> json) => PremiumPayment(
    orderCode: json['orderCode'] is int
        ? json['orderCode'] as int
        : int.tryParse('${json['orderCode']}') ?? 0,
    checkoutUrl: json['checkoutUrl']?.toString() ?? '',
  );
  final int orderCode;
  final String checkoutUrl;
}

class PremiumServiceException implements Exception {
  const PremiumServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}
