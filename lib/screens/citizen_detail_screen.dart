import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/citizen_model.dart';
import '../services/sync_pc_service.dart';

class CitizenDetailScreen extends StatefulWidget {
  final CitizenModel citizen;

  const CitizenDetailScreen({super.key, required this.citizen});

  @override
  State<CitizenDetailScreen> createState() => _CitizenDetailScreenState();
}

class _CitizenDetailScreenState extends State<CitizenDetailScreen> {
  bool _isSyncing = false;
  bool _syncedSuccess = false;
  String? _syncMessage;

  Future<void> _syncToPc() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });

    final result = await SyncPcService.sendCitizenToPc(widget.citizen);

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _syncedSuccess = result['success'] == true;
        _syncMessage = result['message'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_syncMessage ?? ''),
          backgroundColor: _syncedSuccess ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: TextStyle(
                fontSize: isHighlight ? 15 : 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? const Color(0xFF007AFF) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.citizen;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Thông tin Công dân (NFC)'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy thông tin',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: c.toQrString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép chuỗi thông tin CCCD')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Card Thông tin với Ảnh chân dung DG2
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Ảnh chân dung & Tên
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Khung ảnh chân dung từ Chip
                      Container(
                        width: 85,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: c.photoBytes != null && c.photoBytes!.isNotEmpty
                            ? Image.memory(c.photoBytes!, fit: BoxFit.cover)
                            : (c.photoBase64 != null && c.photoBase64!.isNotEmpty
                                ? Image.memory(base64Decode(c.photoBase64!), fit: BoxFit.cover)
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person, size: 45, color: Colors.grey.shade500),
                                      const Text(
                                        'Ảnh Chip',
                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  )),
                      ),
                      const SizedBox(width: 16),
                      // Tên & Số CCCD
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.fullName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.cccdNumber,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007AFF),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.verified, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  c.readMethod,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Bảng thông tin chi tiết
                  _buildInfoRow('Ngày sinh:', c.dateOfBirth),
                  _buildInfoRow('Giới tính:', c.gender),
                  _buildInfoRow('Quê quán:', c.placeOfOrigin),
                  _buildInfoRow('Nơi thường trú:', c.placeOfResidence),
                  _buildInfoRow('Ngày cấp:', c.dateOfIssue),
                  _buildInfoRow('Ngày hết hạn:', c.dateOfExpiry),
                  _buildInfoRow('Số CMND cũ:', c.oldIdNumber),
                  _buildInfoRow('Dân tộc / Tôn giáo:', '${c.ethnicity} / ${c.religion}'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Trạng thái đồng bộ nếu có
            if (_syncMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _syncedSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _syncedSuccess ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _syncedSuccess ? Icons.check_circle : Icons.error,
                      color: _syncedSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _syncMessage!,
                        style: TextStyle(
                          color: _syncedSuccess ? Colors.green.shade900 : Colors.red.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Nút đồng bộ về máy tính PC
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _syncedSuccess ? Colors.green : const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: _isSyncing ? null : _syncToPc,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_syncedSuccess ? Icons.cloud_done : Icons.cloud_upload),
              label: Text(
                _isSyncing
                    ? 'Đang gửi sang PC...'
                    : (_syncedSuccess ? 'ĐÃ ĐỒNG BỘ XONG (GỬI LẠI)' : '⚡ ĐỒNG BỘ VỀ MÁY TÍNH (PC)'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // Nút đọc thẻ tiếp theo
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                'Quét công dân tiếp theo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
