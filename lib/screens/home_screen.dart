import 'package:flutter/material.dart';
import '../services/nfc_cccd_service.dart';
import '../services/sync_pc_service.dart';
import 'scan_mrz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _pcUrl = SyncPcService.defaultUrl;
  bool _isConnected = false;
  bool _isCheckingConnection = false;
  bool _hasNfcHardware = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await SyncPcService.getPcUrl();
    final nfcOk = await NfcCccdService.isNfcAvailable();
    setState(() {
      _pcUrl = url;
      _hasNfcHardware = nfcOk;
    });
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isCheckingConnection = true);
    final ok = await SyncPcService.testConnection(_pcUrl);
    if (mounted) {
      setState(() {
        _isConnected = ok;
        _isCheckingConnection = false;
      });
    }
  }

  void _showConfigPcDialog() {
    final textController = TextEditingController(text: _pcUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cấu hình kết nối PC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập địa chỉ IP và Cổng của máy tính đang chạy phần mềm CCCD_QR_Tool (chung mạng WiFi):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://192.168.1.15:8443',
                labelText: 'Địa chỉ Máy tính PC',
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
            onPressed: () async {
              final newUrl = textController.text.trim();
              if (newUrl.isNotEmpty) {
                await SyncPcService.savePcUrl(newUrl);
                Navigator.pop(ctx);
                setState(() => _pcUrl = newUrl);
                _checkConnection();
              }
            },
            child: const Text('Lưu & Kiểm tra'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.contactless, color: Color(0xFF007AFF)),
            SizedBox(width: 8),
            Text(
              'CCCD NFC Scanner',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ trạng thái kết nối PC
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isConnected ? Colors.green.shade300 : Colors.orange.shade300,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isConnected ? 'Đã kết nối với PC' : 'Chưa kết nối PC',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _isConnected ? Colors.green.shade800 : Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _pcUrl,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: _isCheckingConnection
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.settings, color: Colors.grey),
                    tooltip: 'Đổi IP máy tính',
                    onPressed: _showConfigPcDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Banner cảnh báo nếu máy không có NFC
            if (!_hasNfcHardware)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thiết bị chưa bật hoặc không có phần cứng NFC. Bạn có thể sử dụng chế độ Quét QR bên dưới.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

            const Text(
              'CHỌN PHƯƠNG THỨC TIẾP NHẬN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            // Card 1: ĐỌC CHIP NFC (Phương thức chính)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScanMrzScreen(isNfcMode: true),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF0056B3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.nfc, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ĐỌC CHIP NFC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.verified, color: Colors.amber, size: 18),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Chuẩn ICAO 9303 • Lấy ảnh thẻ gốc • Chống làm giả 100%',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card 2: Quét mã QR truyền thống
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScanMrzScreen(isNfcMode: false),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_scanner, size: 28, color: Colors.black87),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quét mã QR Camera',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Dùng camera quét mã QR mặt trước thẻ',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Hướng dẫn thao tác nhanh
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.help_outline, color: Color(0xFF007AFF), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Quy trình 2 bước đọc chip CCCD:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildStepRow('1', 'Đưa camera quét mã QR (hoặc 3 dòng MRZ mặt sau) để lấy chìa khóa mở chip trong 0.3s.'),
                  const SizedBox(height: 6),
                  _buildStepRow('2', 'Áp thẻ CCCD vào lưng điện thoại 2 giây để trích xuất dữ liệu và ảnh thẻ gốc.'),
                  const SizedBox(height: 6),
                  _buildStepRow('3', 'Bấm nút Đồng bộ để tự động đẩy dữ liệu sang máy tính PC / HIS.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF007AFF),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
          ),
        ),
      ],
    );
  }
}
