/// Lỗi nghiệp vụ được trả từ tầng `data` lên `presentation`.
///
/// Tầng `domain` không phụ thuộc Flutter/Drift/Firebase, nên mọi exception của
/// hạ tầng phải được chuyển thành [Failure] trước khi đi ra ngoài.
sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Lỗi đọc/ghi cơ sở dữ liệu cục bộ (Drift).
final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// Lỗi dữ liệu không hợp lệ do người dùng nhập.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Lỗi xác thực (Firebase Auth).
///
/// [code] giữ mã lỗi gốc của Firebase để phân biệt lỗi mạng với lỗi sai thông
/// tin đăng nhập; [message] đã được dịch sang tiếng Việt để hiển thị thẳng lên
/// UI.
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {this.code});

  final String? code;

  /// Mất mạng hoặc máy chủ không phản hồi trong lúc đăng nhập.
  bool get isNetworkError =>
      code == 'network-request-failed' ||
      code == 'unavailable' ||
      code == 'timeout';
}

/// Lỗi không xác định.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
