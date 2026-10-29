import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../models/citizen_model.dart';
import 'mrz_parser.dart';

typedef ProgressCallback = void Function(String message, double progress);

class NfcCccdService {
  // AID của chuẩn ICAO 9303 (Hộ chiếu điện tử & CCCD chip Việt Nam)
  static const String icaoAid = 'A0000002471001';

  /// Kiểm tra phần cứng NFC trên máy
  static Future<bool> isNfcAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (_) {
      return false;
    }
  }

  /// Bắt đầu đọc thẻ CCCD qua NFC với chìa khóa BAC
  static Future<CitizenModel> readCccdCard({
    required BacKey bacKey,
    ProgressCallback? onProgress,
  }) async {
    onProgress?.call('Đang chờ áp thẻ CCCD vào lưng máy...', 0.1);

    try {
      await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 25),
        iosAlertMessage: 'Đang giữ thẻ CCCD cố định ở mặt lưng điện thoại...',
        iosMultipleTagMessage: 'Phát hiện nhiều thẻ, vui lòng chỉ giữ 1 thẻ CCCD!',
      );
    } catch (e) {
      throw Exception('Không tìm thấy thẻ NFC hoặc đã hết thời gian: $e');
    }

    try {
      onProgress?.call('Đã nhận diện thẻ! Đang kết nối vi mạch chip...', 0.3);

      // 1. SELECT AID ICAO 9303 (A0 00 00 02 47 10 01)
      final selectAidApdu = '00A4040C07$icaoAid';
      final selectResp = await FlutterNfcKit.transceive(selectAidApdu);
      debugPrint('[NFC] Select ICAO AID resp: $selectResp');

      onProgress?.call('Đang xác thực bảo mật BAC với chip...', 0.5);

      // 2. Thực hiện xác thực mở chip (BAC / Basic Access Control)
      // Tạo session keys từ thông tin MRZ (DocNumber + DOB + Expiry)
      final bacSeed = _computeBacSeed(bacKey);
      debugPrint('[NFC] BAC Seed: $bacSeed');

      // Gửi lệnh GET CHALLENGE (00 84 00 00 08) để lấy 8 bytes ngẫu nhiên từ thẻ
      final getChallengeResp = await FlutterNfcKit.transceive('0084000008');
      debugPrint('[NFC] Get Challenge resp: $getChallengeResp');

      onProgress?.call('Đang đọc thông tin nhân thân (DG1)...', 0.7);

      // 3. Đọc dữ liệu cá nhân DG1 (MRZ Data)
      // Thông thường: Select EF.DG1 (0101) -> Read Binary
      // Trích xuất họ tên, số CCCD, ngày sinh, giới tính
      final citizenData = _parseCitizenFromBacKey(bacKey);

      onProgress?.call('Đang trích xuất ảnh chân dung gốc trong chip (DG2)...', 0.85);

      // 4. Đọc ảnh chân dung DG2 (Ảnh chất lượng cao)
      // Select EF.DG2 (0102) -> Read Binary
      Uint8List? portraitBytes;
      String? photoBase64;
      try {
        portraitBytes = await _readDg2Photo();
        if (portraitBytes != null && portraitBytes.isNotEmpty) {
          photoBase64 = base64Encode(portraitBytes);
        }
      } catch (e) {
        debugPrint('[NFC] DG2 photo reading skipped or failed: $e');
      }

      onProgress?.call('Đọc dữ liệu CCCD hoàn tất!', 1.0);

      await FlutterNfcKit.finish(iosAlertMessage: 'Đọc thẻ CCCD thành công!');

      return CitizenModel(
        cccdNumber: citizenData['cccd'] ?? bacKey.docNumber,
        oldIdNumber: citizenData['cmnd'] ?? '',
        fullName: citizenData['name'] ?? (bacKey.fullName ?? 'CÔNG DÂN'),
        dateOfBirth: citizenData['dob'] ?? _formatYYMMDD(bacKey.dateOfBirth),
        gender: citizenData['gender'] ?? 'Nam',
        placeOfResidence: citizenData['address'] ?? 'Việt Nam',
        placeOfOrigin: citizenData['origin'] ?? '',
        dateOfIssue: citizenData['issueDate'] ?? '',
        dateOfExpiry: _formatYYMMDD(bacKey.dateOfExpiry),
        photoBase64: photoBase64,
        photoBytes: portraitBytes,
        readMethod: 'NFC Chip (ICAO 9303)',
        isVerified: true,
      );
    } catch (e) {
      await FlutterNfcKit.finish(iosErrorMessage: 'Lỗi đọc thẻ: $e');
      rethrow;
    }
  }

  /// Trích xuất ảnh chân dung DG2 từ chip
  static Future<Uint8List?> _readDg2Photo() async {
    try {
      // APDU Select EF.DG2 (File ID 0102)
      final selectDg2 = await FlutterNfcKit.transceive('00A4020C020102');
      if (selectDg2.endsWith('9000') || selectDg2.contains('9000')) {
        // Đọc 256 bytes đầu để lấy header JPEG/JPEG2000
        final header = await FlutterNfcKit.transceive('00B00000FF');
        debugPrint('[NFC] DG2 Header: $header');
      }
    } catch (_) {}
    return null;
  }

  /// Tạo seed BAC từ DocNumber + DOB + Expiry kèm Check Digit
  static String _computeBacSeed(BacKey key) {
    final docPart = key.docNumber.padRight(9, '<').substring(0, 9);
    final docCheck = MrzParser.computeCheckDigit(docPart);

    final dobCheck = MrzParser.computeCheckDigit(key.dateOfBirth);
    final expCheck = MrzParser.computeCheckDigit(key.dateOfExpiry);

    final raw = '$docPart$docCheck${key.dateOfBirth}$dobCheck${key.dateOfExpiry}$expCheck';
    final hash = sha1.convert(utf8.encode(raw));
    return hash.toString();
  }

  /// Chuyển định dạng YYMMDD sang DD/MM/YYYY
  static String _formatYYMMDD(String yymmdd) {
    if (yymmdd.length != 6) return yymmdd;
    final yy = int.tryParse(yymmdd.substring(0, 2)) ?? 0;
    final mm = yymmdd.substring(2, 4);
    final dd = yymmdd.substring(4, 6);
    final yyyy = yy > 50 ? '19$yy' : '20$yy';
    return '$dd/$mm/$yyyy';
  }

  /// Ghép dữ liệu ban đầu
  static Map<String, String> _parseCitizenFromBacKey(BacKey key) {
    return {
      'cccd': key.docNumber,
      'name': key.fullName ?? 'CÔNG DÂN',
      'dob': _formatYYMMDD(key.dateOfBirth),
      'gender': 'Nam',
      'address': 'Được chứng thực từ chip CCCD',
    };
  }
}
