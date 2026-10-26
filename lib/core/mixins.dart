import 'exceptions.dart';

// ==========================================
// 2. MIXIN TRONG DART (TÁI SỬ DỤNG TÍNH NĂNG)
// ==========================================
// Mixin cho phép "gắn thêm" (mix-in) chức năng vào nhiều class khác nhau
// mà không cần quan hệ cha - con (kế thừa), sử dụng từ khóa `with`.

/// Mixin 1: Tự động ghi nhật ký (Log)
/// Bất kỳ class nào dùng `with LoggerMixin` đều sở hữu hàm log()
mixin LoggerMixin {
  // Bộ nhớ tạm lưu lại các dòng log để hiển thị trực tiếp lên giao diện
  static final List<String> logs = [];

  void log(String message) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final line = '[$time] [$runtimeType] $message';
    logs.insert(0, line);
    // In ra cửa sổ debug console
    // ignore: avoid_print
    print(line);
  }

  static void clearLogs() {
    logs.clear();
  }
}

/// Mixin 2: Kiểm tra tính hợp lệ của dữ liệu (Validation)
/// Ném ngoại lệ ValidationException nếu dữ liệu không đạt yêu cầu
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

