import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../error/failure.dart';
import 'demo_ai_transport.dart';

/// Phản hồi HTTP tối thiểu mà [AiClient] cần.
///
/// Tách khỏi `http.Response` để test có thể giả lập mọi mã lỗi mà không cần
/// dựng máy chủ thật.
class AiHttpResponse {
  const AiHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

/// Lớp vận chuyển HTTP của [AiClient] — thay được bằng bản giả trong test.
abstract interface class AiTransport {
  Future<AiHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  });

  void close();
}

/// Vận chuyển thật, dùng `package:http` (hoạt động cả trên Android và Web).
class HttpAiTransport implements AiTransport {
  HttpAiTransport({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<AiHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    final response = await _client.post(uri, headers: headers, body: body);
    return AiHttpResponse(statusCode: response.statusCode, body: response.body);
  }

  @override
  void close() => _client.close();
}

/// Client gọi **máy chủ trung gian** tóm tắt ghi chú (#12).
///
/// API key của Gemini nằm ở server; app chỉ biết địa chỉ endpoint, nên không
/// có khoá nào bị nhúng vào APK. Địa chỉ đọc từ `--dart-define`:
///
/// ```bash
/// flutter run --dart-define=AI_SUMMARY_ENDPOINT=https://api.example.com/v1/summarize
/// ```
///
/// Chạy thử giao diện không cần server:
///
/// ```bash
/// flutter run --dart-define=AI_SUMMARY_ENDPOINT=mock
/// ```
///
/// Hợp đồng request/response nằm ở `docs/tom_tat_ai.md`.
class AiClient {
  AiClient({
    required this.endpoint,
    AiTransport? transport,
    this.timeout = const Duration(seconds: 15),
    this.idTokenProvider,
    this.isDemo = false,
  }) : _transport = transport ?? HttpAiTransport();

  /// Giá trị `AI_SUMMARY_ENDPOINT` truyền lúc build.
  static const String configuredEndpoint = String.fromEnvironment(
    'AI_SUMMARY_ENDPOINT',
  );

  /// Giá trị đặc biệt: tóm tắt ngay trên máy, chỉ để demo giao diện.
  static const String demoEndpoint = 'mock';

  /// Đọc cấu hình từ `--dart-define`; endpoint rỗng nghĩa là chưa cấu hình.
  factory AiClient.fromEnvironment({
    Future<String?> Function()? idTokenProvider,
  }) {
    final raw = configuredEndpoint.trim();
    if (raw == demoEndpoint) {
      return AiClient.demo(idTokenProvider: idTokenProvider);
    }
    return AiClient(
      endpoint: raw.isEmpty ? null : Uri.tryParse(raw),
      idTokenProvider: idTokenProvider,
    );
  }

  /// Bản tóm tắt cục bộ (trích câu) — không gọi mạng, không cần API key.
  factory AiClient.demo({Future<String?> Function()? idTokenProvider}) {
    return AiClient(
      endpoint: Uri.parse('$demoEndpoint://summary'),
      transport: const DemoAiTransport(),
      idTokenProvider: idTokenProvider,
      isDemo: true,
    );
  }

  /// `null` khi chưa truyền `AI_SUMMARY_ENDPOINT`.
  final Uri? endpoint;

  /// Thời gian chờ tối đa — tiêu chí #12 yêu cầu kết quả trong ~15 giây.
  final Duration timeout;

  /// `true` khi đang chạy bản tóm tắt cục bộ để demo.
  final bool isDemo;

  /// Callback lấy token Firebase để máy chủ xác thực người dùng.
  final Future<String?> Function()? idTokenProvider;

  final AiTransport _transport;

  bool get isConfigured => isDemo || endpoint != null;

  /// Gửi nội dung ghi chú lên máy chủ và trả về văn bản tóm tắt.
  ///
  /// [mode] là `short`, `long` hoặc `bullets` (khớp cột `mode` bảng
  /// `summaries`). Mọi lỗi hạ tầng được chuyển thành [AiFailure] có thông báo
  /// tiếng Việt; không để exception thô văng ra UI.
  Future<String> summarize({
    required String text,
    required String mode,
    String? noteId,
    String? title,
  }) async {
    final content = text.trim();
    if (content.isEmpty) {
      throw const AiFailure(
        'Ghi chú chưa có nội dung để tóm tắt.',
        kind: AiFailureKind.emptyContent,
      );
    }
    final uri = endpoint;
    if (!isDemo && uri == null) {
      throw const AiFailure(
        'Chưa cấu hình máy chủ tóm tắt AI. Chạy app với '
        '--dart-define=AI_SUMMARY_ENDPOINT=<địa chỉ máy chủ tóm tắt>.',
        kind: AiFailureKind.notConfigured,
      );
    }

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    final body = jsonEncode(<String, Object?>{
      'noteId': noteId,
      'title': title,
      'text': content,
      'mode': mode,
    });

    try {
      final elapsed = Stopwatch()..start();
      if (!isDemo) {
        final token = await idTokenProvider?.call().timeout(timeout);
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
      final remaining = timeout - elapsed.elapsed;
      if (remaining <= Duration.zero) throw TimeoutException('Tóm tắt AI');
      final response = await _transport
          .post(uri!, headers: headers, body: body)
          .timeout(remaining);
      return _readSummary(response);
    } on TimeoutException {
      throw AiFailure(
        'Máy chủ tóm tắt phản hồi quá ${timeout.inSeconds} giây. '
        'Kiểm tra mạng rồi thử lại.',
        kind: AiFailureKind.timeout,
      );
    } on SocketException {
      throw const AiFailure(
        'Không kết nối được máy chủ tóm tắt. Kiểm tra mạng rồi thử lại.',
        kind: AiFailureKind.network,
      );
    } on http.ClientException {
      throw const AiFailure(
        'Không kết nối được máy chủ tóm tắt. Kiểm tra mạng rồi thử lại.',
        kind: AiFailureKind.network,
      );
    }
  }

  /// Đọc nội dung tóm tắt từ phản hồi, đồng thời dịch mã HTTP sang [AiFailure].
  String _readSummary(AiHttpResponse response) {
    final status = response.statusCode;
    if (status != 200) {
      throw AiFailure(_messageForStatus(status), kind: _kindForStatus(status));
    }

    final summary = _extractText(response.body);
    if (summary == null || summary.isEmpty) {
      throw const AiFailure(
        'Máy chủ trả về kết quả rỗng. Thử lại sau.',
        kind: AiFailureKind.badResponse,
      );
    }
    return summary;
  }

  /// Chấp nhận `{"summary": ...}`, `{"content": ...}`, `{"data": {"summary": ...}}`
  /// hoặc văn bản thuần để máy chủ của nhóm không phải sửa lại.
  String? _extractText(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is String) {
        return decoded.trim();
      }
      if (decoded is Map<String, dynamic>) {
        for (final key in const <String>['summary', 'content']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final value = data['summary'] ?? data['content'];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
        return null;
      }
      return null;
    } on FormatException {
      // Máy chủ trả văn bản thuần thay vì JSON — vẫn dùng được.
      return trimmed;
    }
  }

  AiFailureKind _kindForStatus(int status) {
    if (status == 401 || status == 403) {
      return AiFailureKind.unauthorized;
    }
    if (status == 429) {
      return AiFailureKind.quotaExceeded;
    }
    if (status == 504) {
      return AiFailureKind.timeout;
    }
    if (status >= 500) {
      return AiFailureKind.server;
    }
    return AiFailureKind.badResponse;
  }

  String _messageForStatus(int status) {
    if (status == 401 || status == 403) {
      return 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. '
          'Đăng nhập lại rồi thử lại.';
    }
    if (status == 429) {
      return 'Đã hết lượt gọi AI. Thử lại sau hoặc báo nhóm trưởng.';
    }
    if (status == 504) {
      return 'Máy chủ tóm tắt phản hồi quá lâu. Thử lại sau.';
    }
    if (status == 413) {
      return 'Ghi chú quá dài để tóm tắt. Hãy chia nội dung thành các phần ngắn hơn.';
    }
    if (status >= 500) {
      return 'Máy chủ tóm tắt đang gặp lỗi. Thử lại sau ít phút.';
    }
    return 'Máy chủ tóm tắt trả về lỗi (HTTP $status). Thử lại sau.';
  }

  /// Giải phóng kết nối HTTP khi app đóng.
  void close() => _transport.close();
}
