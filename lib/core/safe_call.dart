import 'exceptions.dart';
import 'mixins.dart';
import 'result.dart';

// ===== WRAPPER BẮT LỖI TẬP TRUNG =====
// Mọi thao tác có thể lỗi đều được bọc qua safeCall().
// Lỗi được bắt ở MỘT chỗ duy nhất và đổi thành thông báo thân thiện,
// nên ứng dụng không bao giờ bị crash.
class ErrorHandler with LoggerMixin {
  static final _instance = ErrorHandler._();
  ErrorHandler._();

  Future<Result<T>> safeCall<T>(Future<T> Function() action, {String task = 'Thao tác'}) async {
    try {
      log('Bắt đầu: $task');
      final data = await action();
      return Result.success(data);
    } on AppException catch (e) {
      // Lỗi có chủ đích: đã có sẵn thông báo thân thiện
      log('Lỗi ứng dụng: $e');
      return Result.failure(e.message);
    } on FormatException catch (e) {
      // Lỗi của Dart khi chuỗi JSON sai cú pháp
      log('Lỗi định dạng: ${e.message}');
      return Result.failure('Dữ liệu không đúng định dạng JSON');
    } catch (e, stack) {
      // Mọi lỗi bất ngờ khác
      log('Lỗi không xác định: $e\n$stack');
      return Result.failure('Đã có lỗi xảy ra, vui lòng thử lại');
    } finally {
      // Luôn chạy, dù thành công hay thất bại
      log('Kết thúc: $task');
    }
  }
}

/// Hàm tiện dụng để gọi: `await safeCall(() => ...)`.
Future<Result<T>> safeCall<T>(Future<T> Function() action, {String task = 'Thao tác'}) =>
    ErrorHandler._instance.safeCall(action, task: task);
