class BacKey {
  final String docNumber;
  final String dateOfBirth; // YYMMDD
  final String dateOfExpiry; // YYMMDD
  final String? fullName;

  BacKey({
    required this.docNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    this.fullName,
  });

  @override
  String toString() => 'BacKey(doc: $docNumber, dob: $dateOfBirth, exp: $dateOfExpiry)';
}

class MrzParser {
  /// Parse 3 dòng MRZ (Chuẩn TD1 trên mặt sau CCCD)
  static BacKey? parseMrzLines(List<String> rawLines) {
    // Làm sạch ký tự lạ, khoảng trắng, chuyển hoa
    final lines = rawLines
        .map((l) => l.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9<]'), ''))
        .where((l) => l.length >= 28)
        .toList();

    if (lines.length < 3) return null;

    // Line 1: Ví dụ IDVNM0520980001235<<<<<<<<<<<<
    // Line 2: Ví dụ 9808154M3808152VNM<<<<<<<<<<<2
    // Line 3: Ví dụ NGUYEN<<VAN<A<<<<<<<<<<<<<<<<<
    final l1 = lines[0];
    final l2 = lines[1];
    final l3 = lines[2];

    try {
      // 1. Số thẻ (Doc Number) nằm ở line 1, từ vị trí 5 (sau IDVNM)
      String docNumber = '';
      if (l1.length >= 15) {
        docNumber = l1.substring(5, 14).replaceAll('<', '');
        // Với CCCD 12 số, phần mở rộng nằm ở cuối dòng 1
        final ext = l1.substring(15).replaceAll('<', '');
        if (docNumber.length < 12 && ext.isNotEmpty) {
          docNumber += ext;
        }
      }

      // 2. Ngày sinh (YYMMDD) ở line 2 từ vị trí 0..6
      final dob = l2.substring(0, 6);

      // 3. Ngày hết hạn (YYMMDD) ở line 2 từ vị trí 8..14
      final expiry = l2.substring(8, 14);

      // 4. Họ tên ở line 3
      final nameRaw = l3.replaceAll('<', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

      if (docNumber.isNotEmpty && dob.length == 6 && expiry.length == 6) {
        return BacKey(
          docNumber: docNumber,
          dateOfBirth: dob,
          dateOfExpiry: expiry,
          fullName: nameRaw,
        );
      }
    } catch (_) {}

    return null;
  }

  /// Parse từ chuỗi mã QR mặt trước CCCD:
  /// Định dạng: Số_CCCD|Số_CMND|Họ_tên|Ngày_sinh(DDMMYYYY)|Giới_tính|Địa_chỉ|Ngày_cấp(DDMMYYYY)
  static BacKey? parseQrString(String qrContent) {
    final parts = qrContent.split('|');
    if (parts.length < 6) return null;

    final cccd = parts[0].trim();
    final name = parts[2].trim();
    final dobRaw = parts[3].trim(); // DDMMYYYY (vd: 15081998)

    if (cccd.length < 9 || dobRaw.length < 8) return null;

    final d = dobRaw.substring(0, 2);
    final m = dobRaw.substring(2, 4);
    final y = dobRaw.substring(4, 8);

    final birthYear = int.tryParse(y) ?? 2000;
    // Chuyển sang YYMMDD cho chuẩn ICAO
    final dobYYMMDD = '${y.substring(2, 4)}$m$d';

    // Theo Luật Căn cước Việt Nam, CCCD có hạn đến các mốc: 25 tuổi, 40 tuổi, 60 tuổi
    final currentYear = DateTime.now().year;
    final age = currentYear - birthYear;
    int expYear;
    if (age < 25) {
      expYear = birthYear + 25;
    } else if (age < 40) {
      expYear = birthYear + 40;
    } else if (age < 60) {
      expYear = birthYear + 60;
    } else {
      // Trên 60 tuổi được cấp vô thời hạn (thường để 9999 hoặc +30 năm)
      expYear = birthYear + 80;
    }

    final expYearStr = expYear.toString();
    final expiryYYMMDD = '${expYearStr.substring(expYearStr.length - 2)}$m$d';

    return BacKey(
      docNumber: cccd,
      dateOfBirth: dobYYMMDD,
      dateOfExpiry: expiryYYMMDD,
      fullName: name,
    );
  }

  /// Tính check digit ICAO 7-3-1
  static int computeCheckDigit(String data) {
    const weights = [7, 3, 1];
    int sum = 0;
    for (int i = 0; i < data.length; i++) {
      final c = data[i];
      int val = 0;
      if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
        val = c.codeUnitAt(0) - 48;
      } else if (c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90) {
        val = c.codeUnitAt(0) - 55;
      } else if (c == '<') {
        val = 0;
      }
      sum += val * weights[i % 3];
    }
    return sum % 10;
  }
}
