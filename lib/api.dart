import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'core.dart';


const String kBaseUrl ='http://127.0.0.1:8000';   // немесе http://localhost:8000;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Backend-ten kelgen transaction bir jazbasy.
class ApiTx {
  final int id;
  final double amount;
  final String recipient, city, status;
  final int riskScore;
  final Risk risk;
  final List<String> reasons;
  final DateTime createdAt;

  ApiTx({
    required this.id,
    required this.amount,
    required this.recipient,
    required this.city,
    required this.status,
    required this.riskScore,
    required this.risk,
    required this.reasons,
    required this.createdAt,
  });

  factory ApiTx.fromJson(Map<String, dynamic> j) => ApiTx(
        id: j['id'],
        amount: (j['amount'] as num).toDouble(),
        recipient: j['recipient'] ?? '',
        city: j['city'] ?? '',
        status: j['status'] ?? 'pending',
        riskScore: j['risk_score'] ?? 0,
        risk: _riskFromString(j['risk_level']),
        reasons: List<String>.from(j['reasons'] ?? []),
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

Risk _riskFromString(String? s) {
  switch (s) {
    case 'danger':
      return Risk.danger;
    case 'warn':
      return Risk.warn;
    default:
      return Risk.safe;
  }
}

class Api {
  Api._();
  static String? token;
  static String? phone;

  /// Splash экранында shaqyrylady: bұрын кіргенбіз бе тексереді.
  static Future<bool> restoreSession() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
    phone = p.getString('phone');
    return token != null;
  }

  static Future<void> _saveSession(String tok, String ph) async {
    token = tok;
    phone = ph;
    final p = await SharedPreferences.getInstance();
    await p.setString('token', tok);
    await p.setString('phone', ph);
  }

  static Future<void> logout() async {
    token = null;
    phone = null;
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Uri _u(String path) => Uri.parse('$kBaseUrl$path');

  static dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return r.body.isEmpty ? {} : jsonDecode(utf8.decode(r.bodyBytes));
    }
    String msg = 'Қате (${r.statusCode})';
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw ApiException(msg);
  }

  static Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Серверге қосыла алмадық. Интернетті және backend '
          'серверінің қосулы тұрғанын тексеріңіз.');
    }
  }

  // ---------------- AUTH ----------------
  static Future<String> register(String phone) => _guard(() async {
        final r = await http.post(_u('/auth/register'),
            headers: _headers, body: jsonEncode({'phone': phone}));
        final j = _decode(r);
        return j['dev_code'] as String; // DEV: nagyzynda SMS keledi
      });

  static Future<void> verifyOtp(String phone, String code, String pin) => _guard(() async {
        final r = await http.post(_u('/auth/verify-otp'),
            headers: _headers,
            body: jsonEncode({'phone': phone, 'code': code, 'pin': pin}));
        final j = _decode(r);
        await _saveSession(j['access_token'], phone);
      });

  static Future<void> login(String phone, String pin) => _guard(() async {
        final r = await http.post(_u('/auth/login'),
            headers: _headers, body: jsonEncode({'phone': phone, 'pin': pin}));
        final j = _decode(r);
        await _saveSession(j['access_token'], phone);
      });

  // ---------------- NOMIR ----------------
  static Future<Map<String, dynamic>> checkNumber(String phone) => _guard(() async {
        final r = await http.get(_u('/check-number?phone=${Uri.encodeComponent(phone)}'),
            headers: _headers);
        return _decode(r);
      });

  static Future<void> reportNumber(String phone, String category, String comment) =>
      _guard(() async {
        final r = await http.post(_u('/report'),
            headers: _headers,
            body: jsonEncode({'phone': phone, 'category': category, 'comment': comment}));
        _decode(r);
      });

  // ---------------- SILTEME / MATIN ----------------
  static Future<Map<String, dynamic>> checkUrl(String url) => _guard(() async {
        final r = await http.post(_u('/check-url'),
            headers: _headers, body: jsonEncode({'url': url}));
        return _decode(r);
      });

  static Future<Map<String, dynamic>> checkText(String text) => _guard(() async {
        final r = await http.post(_u('/check-text'),
            headers: _headers, body: jsonEncode({'text': text}));
        return _decode(r);
      });

  // ---------------- TRANSAKTSIALAR ----------------
  static Future<List<ApiTx>> listTransactions() => _guard(() async {
        final r = await http.get(_u('/transactions'), headers: _headers);
        final j = _decode(r) as List;
        return j.map((e) => ApiTx.fromJson(e)).toList();
      });

  static Future<ApiTx> createTransaction({
    required double amount,
    String recipient = '',
    String city = '',
    bool recipientNew = false,
    bool deviceNew = false,
  }) =>
      _guard(() async {
        final r = await http.post(_u('/transactions'),
            headers: _headers,
            body: jsonEncode({
              'amount': amount,
              'recipient': recipient,
              'city': city,
              'recipient_new': recipientNew,
              'device_new': deviceNew,
            }));
        return ApiTx.fromJson(_decode(r));
      });

  static Future<ApiTx> decideTransaction(int id, String action) => _guard(() async {
        final r = await http.post(_u('/transactions/$id/decide'),
            headers: _headers, body: jsonEncode({'action': action}));
        return ApiTx.fromJson(_decode(r));
      });
}