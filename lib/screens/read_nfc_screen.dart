import 'package:flutter/material.dart';
import '../services/mrz_parser.dart';
import '../services/nfc_cccd_service.dart';
import '../widgets/nfc_wave_animation.dart';
import 'citizen_detail_screen.dart';

class ReadNfcScreen extends StatefulWidget {
  final BacKey bacKey;
  final String? rawQr;

  const ReadNfcScreen({
    super.key,
    required this.bacKey,
    this.rawQr,
  });

  @override
  State<ReadNfcScreen> createState() => _ReadNfcScreenState();
}

class _ReadNfcScreenState extends State<ReadNfcScreen> {
  String _statusMessage = 'Đang khởi động cảm biến NFC...';
  double _progress = 0.05;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startNfcReading();
  }

  Future<void> _startNfcReading() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progress = 0.1;
      _statusMessage = 'Hãy áp mặt lưng thẻ CCCD vào phần trên mặt lưng điện thoại...';
    });

    try {
      final citizen = await NfcCccdService.readCccdCard(
        bacKey: widget.bacKey,
        onProgress: (msg, prog) {
          if (mounted) {
            setState(() {
              _statusMessage = msg;
              _progress = prog;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _progress = 1.0;
        });

        // Chuyển sang màn hình hiển thị kết quả chi tiết
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CitizenDetailScreen(citizen: citizen),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Bước 2: Đọc Chip CCCD (NFC)'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thông tin khóa đã quét
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key, color: Color(0xFF007AFF), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Đã có chìa khóa: Số ${widget.bacKey.docNumber} | Sinh: ${widget.bacKey.dateOfBirth}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Hiệu ứng sóng NFC sống động
              if (_isLoading) ...[
                const NfcWaveAnimation(size: 200, color: Color(0xFF007AFF)),
                const SizedBox(height: 32),
              ] else if (_errorMessage != null) ...[
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline, size: 50, color: Colors.red.shade700),
                ),
                const SizedBox(height: 24),
              ],

              // Thanh tiến trình
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _errorMessage != null ? Colors.red : const Color(0xFF007AFF),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Thông báo trạng thái
              Text(
                _errorMessage ?? _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _errorMessage != null ? Colors.red.shade700 : Colors.black87,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _isLoading
                    ? '💡 Mẹo: Giữ cố định thẻ CCCD sát vào cụm camera hoặc nửa trên mặt lưng điện thoại trong 2-3 giây.'
                    : '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),

              const Spacer(),

              // Nút Thử lại hoặc Quay lại khi có lỗi
              if (_errorMessage != null) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _startNfcReading,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử áp thẻ lại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại quét mã khác'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
