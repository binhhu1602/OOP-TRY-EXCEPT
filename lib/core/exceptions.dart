// ===== CUSTOM EXCEPTION =====
// Lớp lỗi gốc của ứng dụng. Mọi lỗi "có chủ đích" đều kế thừa từ đây,
// mỗi lỗi mang theo một thông báo thân thiện để hiển thị cho người dùng.
class AppException implements Exception {
  final String message; // Thông báo cho người dùng
  final String? details; // Chi tiết kỹ thuật (dành cho log)

  const AppException(this.message, {this.details});

  @override
  String toString() => '$runtimeType: $message${details != null ? ' ($details)' : ''}';
}

/// Dữ liệu nhập vào không hợp lệ (tên trống, giá âm...).
class ValidationException extends AppException {
  const ValidationException(super.message, {super.details});
}

/// Dữ liệu JSON/Map sai định dạng, thiếu trường.
class ParseException extends AppException {
  const ParseException(super.message, {super.details});
}

/// Không tìm thấy dữ liệu.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.details});
}
