import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Hiển thị khi Firebase chưa được cấu hình, thay vì để app crash khó hiểu.
class FirebaseConfigErrorPage extends StatelessWidget {
  const FirebaseConfigErrorPage({required this.detail, super.key});

  final String detail;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.settings_suggest_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa cấu hình Firebase',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    kIsWeb
                        ? 'Nhận bản config/shared_client.json có cấu hình Web '
                              'từ nhóm, rồi chạy flutter run -d chrome '
                              '--dart-define-from-file=config/shared_client.json.'
                        : 'Nhận file config/shared_client.json từ nhóm và chạy '
                              'Flutter với --dart-define-from-file=config/shared_client.json. '
                              'Nếu dùng Firebase riêng, xem hướng dẫn trong README.',
                  ),
                  const SizedBox(height: 12),
                  Text(detail),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
