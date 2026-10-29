import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/mrz_parser.dart';
import 'read_nfc_screen.dart';

class ScanMrzScreen extends StatefulWidget {
  final bool isNfcMode; // true = quét lấy key đọc NFC, false = quét QR truyền thống

  const ScanMrzScreen({super.key, this.isNfcMode = true});

  @override
  State<ScanMrzScreen> createState() => _ScanMrzScreenState();
}

class _ScanMrzScreenState extends State<ScanMrzScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  final TextEditingController _canController = TextEditingController();

  @override
  void dispose() {
    _scannerController.dispose();
    _canController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _isProcessing = true;
        _processScannedText(rawValue);
        break;
      }
    }
  }

  void _processScannedText(String text) {
    final bacKey = MrzParser.parseQrString(text);

    if (bacKey != null) {
      if (widget.isNfcMode) {
        // Chuyển sang màn hình đọc thẻ NFC với chìa khóa vừa quét được
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReadNfcScreen(bacKey: bacKey, rawQr: text),
          ),
        );
      } else {
        Navigator.pop(context, text);
      }
    } else {
      // Thử xem có phải 3 dòng MRZ không
      final lines = text.split('\n');
      final mrzKey = MrzParser.parseMrzLines(lines);
      if (mrzKey != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReadNfcScreen(bacKey: mrzKey),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa nhận diện đúng mã QR hoặc MRZ của thẻ CCCD!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isProcessing = false);
        });
      }
    }
  }

  void _showManualCanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập mã CAN (6 số)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mã CAN gồm 6 chữ số in ở góc phải phía dưới mặt trước thẻ CCCD.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _canController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'VD: 123456',
                labelText: 'Mã số CAN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final can = _canController.text.trim();
              if (can.length == 6) {
                Navigator.pop(ctx);
                final mockKey = BacKey(
                  docNumber: can,
                  dateOfBirth: '000101',
                  dateOfExpiry: '990101',
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReadNfcScreen(bacKey: mockKey),
                  ),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.isNfcMode ? 'Bước 1: Quét khóa mở Chip' : 'Quét mã QR CCCD',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: Colors.amber,
                );
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // Khung ngắm quét (Viewfinder Overlay)
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF007AFF), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Dải hướng dẫn phía trên
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.isNfcMode
                    ? '🎯 Đưa camera vào MÃ QR mặt trước hoặc 3 DÒNG MRZ mặt sau để lấy khóa mở chip tự động.'
                    : '🎯 Đưa mã QR trên thẻ CCCD vào khung hình để quét.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ),
          ),

          // Nút nhập tay mã CAN phía dưới
          if (widget.isNfcMode)
            Positioned(
              bottom: 30,
              left: 30,
              right: 30,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showManualCanDialog,
                icon: const Icon(Icons.pin, color: Color(0xFF007AFF)),
                label: const Text(
                  'Thẻ bị mờ? Nhập mã CAN (6 số)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
