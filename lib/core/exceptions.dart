// ==========================================
// 1. ĐỊNH NGHĨA LỖI TÙY BIẾN (CUSTOM EXCEPTION)
// ==========================================

/// Lớp lỗi cơ sở của ứng dụng (Base Exception).
/// Mọi lỗi nghiệp vụ đều kế thừa từ đây để có thông báo thân thiện cho người dùng.
class AppException implements Exception {
  final String message; // Thông báo thân thiện để hiển thị lên màn hình
  final String? details; // Chi tiết kỹ thuật dành cho lập trình viên/log

  const AppException(this.message, {this.details});

  @override
  String toString() => '$runtimeType: $message${details != null ? ' ($details)' : ''}';
}

/// Lỗi 1: Dữ liệu nhập vào không hợp lệ (tên trống, giá âm, không phải là số...)
class ValidationException extends AppException {
  const ValidationException(super.message, {super.details});
}

/// Lỗi 2: Dữ liệu JSON / Map bị sai định dạng hoặc thiếu trường bắt buộc
class ParseException extends AppException {
  const ParseException(super.message, {super.details});
}

/// Lỗi 3: Không tìm thấy đối tượng trong danh sách theo ID
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.details});
}

