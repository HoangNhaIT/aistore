import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/sync_pc_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Bỏ qua kiểm tra chứng chỉ SSL tự ký khi kết nối mạng LAN với máy tính PC
  HttpOverrides.global = CustomHttpOverrides();

  // Khóa hướng màn hình dọc để quét thẻ tiện lợi nhất
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const CccdNfcApp());
}

class CccdNfcApp extends StatelessWidget {
  const CccdNfcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCCD NFC Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          primary: const Color(0xFF007AFF),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
