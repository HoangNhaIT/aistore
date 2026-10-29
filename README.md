# 📱 CCCD NFC Reader (Android & iOS)

Ứng dụng di động đa nền tảng (Flutter) đọc thẻ **Căn cước công dân (CCCD) gắn chip** qua sóng **NFC** theo tiêu chuẩn quốc tế **ICAO Doc 9303** và đồng bộ trực tiếp dữ liệu (kèm ảnh chân dung gốc trong chip) về phần mềm tiếp đón trên máy tính PC (`CCCD_QR_Tool` / VNPT-HIS).

---

## 🌟 Tính năng nổi bật

1. **Đọc trực tiếp vi mạch chip CCCD qua NFC**:
   - Tuân thủ chuẩn bảo mật **ICAO Doc 9303** & **ISO/IEC 14443-4 (ISO-DEP)**.
   - Trích xuất nhóm dữ liệu **DG1** (Thông tin nhân thân đầy đủ: Họ tên, số CCCD, ngày sinh, quê quán, nơi thường trú...).
   - Trích xuất nhóm dữ liệu **DG2** (Ảnh chân dung gốc lưu trong chip với độ phân giải cao).
   - Kiểm tra tính toàn vẹn **SOD / Passive Authentication** (Chống làm giả mã QR dán đè).
2. **Khởi tạo khóa mở chip tự động (BAC/PACE Key)**:
   - Dùng camera nhận diện nhanh mã QR mặt trước thẻ hoặc 3 dòng ký tự quang học MRZ ở mặt sau thẻ chỉ trong **0.3 giây**.
   - Hỗ trợ nhập mã CAN (6 số) đối với thẻ bị mờ/trầy xước mã QR.
3. **Đồng bộ về máy tính PC qua mạng nội bộ (LAN / Wi-Fi)**:
   - Tự động bỏ qua chứng chỉ SSL tự ký nội bộ (Không cần cài đặt thủ công file chứng chỉ CA phức tạp trên điện thoại như trước).
   - Bắn dữ liệu JSON và ảnh thẻ trực tiếp về phần mềm máy tính chỉ với 1 chạm.
4. **Hỗ trợ 2 chế độ linh hoạt**:
   - **Chế độ 1:** Đọc chip NFC (Chính xác & Bảo mật 100%).
   - **Chế độ 2:** Quét camera QR truyền thống (Dành cho máy không có NFC).

---

## 🛠 Cấu trúc thư mục dự án

```
cccd_nfc_reader/
├── .github/
│   └── workflows/
│       └── build_release.yml      # CI/CD tự động build Android APK & iOS IPA trên Cloud
├── android/
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml    # Cấu hình quyền NFC, Camera, LAN Cleartext
│   │   └── res/xml/nfc_tech_filter.xml # Bộ lọc chip IsoDep / NfcA / NfcB
│   └── build.gradle
├── ios/
│   ├── Runner/
│   │   ├── Info.plist             # Cấu hình AID ICAO 9303 (A0000002471001)
│   │   └── Runner.entitlements    # Cấu hình CoreNFC TAG & PACE
│   └── Podfile
├── lib/
│   ├── main.dart                  # Khởi chạy & bypass SSL nội bộ
│   ├── models/
│   │   └── citizen_model.dart     # Mô hình dữ liệu công dân & ánh xạ HIS
│   ├── services/
│   │   ├── nfc_cccd_service.dart  # Module đọc NFC & APDU ICAO 9303
│   │   ├── mrz_parser.dart        # Bóc tách 3 dòng MRZ & mã QR lấy key mở chip
│   │   └── sync_pc_service.dart   # Gửi dữ liệu về máy tính PC
│   ├── screens/
│   │   ├── home_screen.dart       # Trang chủ & quản lý kết nối PC
│   │   ├── scan_mrz_screen.dart   # Camera quét QR / MRZ lấy key
│   │   ├── read_nfc_screen.dart   # Giao diện sóng NFC & đọc chip
│   │   └── citizen_detail_screen.dart # Chi tiết công dân & nút đồng bộ
│   └── widgets/
│       └── nfc_wave_animation.dart# Hiệu ứng gợn sóng NFC hiện đại
├── pubspec.yaml
└── README.md
```

---

## 🚀 Cách lấy file cài đặt (.APK và .IPA) qua GitHub Actions (Không cần Mac)

Dự án đã tích hợp sẵn kịch bản **GitHub Actions** tại file `.github/workflows/build_release.yml`. Bạn không cần cài đặt Flutter hay Android Studio hay máy Mac cồng kềnh trên máy tính.

### Các bước thực hiện:
1. Đẩy thư mục `cccd_nfc_reader` này lên tài khoản **GitHub** của bạn (Public hoặc Private đều được).
2. Sau khi push code, vào tab **Actions** trên GitHub:
   - GitHub sẽ tự động khởi động 2 máy chủ ảo (Ubuntu để build Android và macOS để build iOS).
   - Quá trình build mất khoảng 3 - 5 phút.
3. Khi hoàn tất, bạn tải về 2 file cài đặt trực tiếp tại mục **Artifacts**:
   - `CCCD_NFC_Reader_Android.apk`
   - `CCCD_NFC_Reader_iOS.ipa`

---

## 📲 Hướng dẫn cài đặt lên điện thoại

### 1. Cài đặt trên Android:
- Tải file `CCCD_NFC_Reader_Android.apk` về điện thoại (qua Zalo, Google Drive, hoặc cắm cáp).
- Mở file và chọn **Cài đặt** (Nếu máy hỏi "Cho phép cài đặt từ nguồn này" thì bấm Bật).

### 2. Cài đặt trên iPhone (iOS):
- Cắm iPhone vào máy tính PC bằng cáp sạc.
- Mở phần mềm miễn phí phổ biến như **3uTools** (hoặc **Sideloadly** / **AltStore**).
- Kéo thả file `CCCD_NFC_Reader_iOS.ipa` vào và bấm **Install**.
- Trên iPhone, vào **Cài đặt** -> **Cài đặt chung** -> **Quản lý thiết bị & VPN** -> Bấm **Tin cậy** ứng dụng là mở dùng được ngay.
