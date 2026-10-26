import 'exceptions.dart';

// ===== MIXIN =====
// Mixin cho phép "gắn thêm" tính năng vào nhiều class khác nhau
// mà không cần kế thừa (dùng từ khóa `with`).

/// Tự động ghi log. Class nào `with LoggerMixin` đều có hàm log().
mixin LoggerMixin {
  // Danh sách log dùng chung để giao diện hiển thị.
  static final List<String> logs = [];

  void log(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final line = '[$time] [$runtimeType] $message';
    logs.insert(0, line);
    // ignore: avoid_print
    print(line);
  }
}

/// Các hàm kiểm tra tính hợp lệ, ném ValidationException nếu sai.
mixin ValidatorMixin {
  void requireNotEmpty(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ValidationException('$fieldName không được để trống');
    }
  }

  void requirePositive(num value, String fieldName) {
    if (value <= 0) {
      throw ValidationException('$fieldName phải lớn hơn 0', details: 'value=$value');
    }
  }
}
