import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/citizen_model.dart';

/// Bỏ qua kiểm tra chứng chỉ SSL tự ký (Self-signed) để không phải cài đặt CA certificate trên điện thoại
class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class SyncPcService {
  static const String _prefKeyPcUrl = 'pc_sync_url';
  static const String defaultUrl = 'https://192.168.1.10:8443';

  static Future<String> getPcUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyPcUrl) ?? defaultUrl;
  }

  static Future<void> savePcUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    var cleanUrl = url.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    await prefs.setString(_prefKeyPcUrl, cleanUrl);
  }

  /// Kiểm tra kết nối tới máy tính PC
  static Future<bool> testConnection(String baseUrl) async {
    try {
      final uri = Uri.parse('$baseUrl/api/patients');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      return res.statusCode == 200 || res.statusCode == 404;
    } catch (_) {
      try {
        final fallbackUri = Uri.parse(baseUrl);
        final res = await http.get(fallbackUri).timeout(const Duration(seconds: 4));
        return res.statusCode < 500;
      } catch (_) {
        return false;
      }
    }
  }

  /// Gửi dữ liệu công dân đọc từ chip NFC về phần mềm trên PC
  static Future<Map<String, dynamic>> sendCitizenToPc(CitizenModel citizen) async {
    final baseUrl = await getPcUrl();
    final rowData = citizen.toRowData();
    final draftId = 'NFC_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final uri = Uri.parse('$baseUrl/api/patients');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'draft_id': draftId,
          'row': rowData,
          'source': 'mobile_nfc',
          'is_verified': citizen.isVerified,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Đồng bộ thành công về máy tính!',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Máy tính từ chối (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối tới PC: $e. Hãy kiểm tra chung mạng WiFi và địa chỉ IP.',
      };
    }
  }
}
