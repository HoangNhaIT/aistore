import 'dart:convert';
import 'dart:typed_data';

class CitizenModel {
  final String cccdNumber;
  final String oldIdNumber;
  final String fullName;
  final String dateOfBirth; // DD/MM/YYYY
  final String gender; // Nam / Nữ
  final String nationality;
  final String ethnicity;
  final String religion;
  final String placeOfOrigin; // Quê quán
  final String placeOfResidence; // Thường trú
  final String dateOfIssue; // DD/MM/YYYY
  final String dateOfExpiry; // DD/MM/YYYY
  final String? photoBase64;
  final Uint8List? photoBytes;
  final String readMethod; // "NFC Chip (ICAO 9303)" | "Camera QR"
  final bool isVerified;
  final DateTime scannedAt;

  CitizenModel({
    required this.cccdNumber,
    this.oldIdNumber = '',
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.nationality = 'Việt Nam',
    this.ethnicity = 'Kinh',
    this.religion = 'Không',
    this.placeOfOrigin = '',
    required this.placeOfResidence,
    this.dateOfIssue = '',
    this.dateOfExpiry = '',
    this.photoBase64,
    this.photoBytes,
    this.readMethod = 'NFC Chip (ICAO 9303)',
    this.isVerified = true,
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();

  /// Chuyển đổi thành row data gửi tới máy tính (CCCD_QR_Tool / HIS)
  Map<String, dynamic> toRowData() {
    return {
      'CCCD': cccdNumber,
      'CMND': oldIdNumber,
      'TENBENHNHAN': fullName,
      'NGAYSINH': dateOfBirth,
      'GIOITINH': gender,
      'DIACHI': placeOfResidence,
      'QUEQUAN': placeOfOrigin,
      'DANTOC': ethnicity,
      'QUOCTICH': nationality,
      'NGAYCAP': dateOfIssue,
      'NGAYHETHAN': dateOfExpiry,
      'READ_METHOD': readMethod,
      'IS_VERIFIED': isVerified ? '1' : '0',
      'PHOTO_BASE64': photoBase64 ?? '',
    };
  }

  /// Chuỗi định dạng chuẩn tương thích với mã QR CCCD truyền thống
  String toQrString() {
    return '$cccdNumber|$oldIdNumber|$fullName|${dateOfBirth.replaceAll('/', '')}|$gender|$placeOfResidence|${dateOfIssue.replaceAll('/', '')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'cccdNumber': cccdNumber,
      'oldIdNumber': oldIdNumber,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'nationality': nationality,
      'ethnicity': ethnicity,
      'religion': religion,
      'placeOfOrigin': placeOfOrigin,
      'placeOfResidence': placeOfResidence,
      'dateOfIssue': dateOfIssue,
      'dateOfExpiry': dateOfExpiry,
      'photoBase64': photoBase64,
      'readMethod': readMethod,
      'isVerified': isVerified,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  factory CitizenModel.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    if (json['photoBase64'] != null && json['photoBase64'].toString().isNotEmpty) {
      try {
        bytes = base64Decode(json['photoBase64']);
      } catch (_) {}
    }
    return CitizenModel(
      cccdNumber: json['cccdNumber'] ?? '',
      oldIdNumber: json['oldIdNumber'] ?? '',
      fullName: json['fullName'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
      nationality: json['nationality'] ?? 'Việt Nam',
      ethnicity: json['ethnicity'] ?? 'Kinh',
      religion: json['religion'] ?? 'Không',
      placeOfOrigin: json['placeOfOrigin'] ?? '',
      placeOfResidence: json['placeOfResidence'] ?? '',
      dateOfIssue: json['dateOfIssue'] ?? '',
      dateOfExpiry: json['dateOfExpiry'] ?? '',
      photoBase64: json['photoBase64'],
      photoBytes: bytes,
      readMethod: json['readMethod'] ?? 'NFC Chip',
      isVerified: json['isVerified'] ?? true,
      scannedAt: json['scannedAt'] != null ? DateTime.tryParse(json['scannedAt']) : null,
    );
  }
}
