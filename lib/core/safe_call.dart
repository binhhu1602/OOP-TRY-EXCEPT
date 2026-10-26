import 'exceptions.dart';
import 'mixins.dart';
import 'result.dart';

// ==========================================
// 4. KỸ THUẬT XỬ LÝ LỖI: TRY - CATCH - FINALLY
// ==========================================
// - try: Thực thi khối lệnh có nguy cơ ném ra ngoại lệ.
// - on <LoạiLỗi> catch (e): Bắt chính xác loại lỗi mong muốn.
// - catch (e): Bắt tất cả các lỗi còn lại chưa lường trước.
// - finally: Khối lệnh LUÔN ĐƯỢC CHẠY dù có lỗi hay không (để đóng tài nguyên, log kết thúc).
class ErrorHandler with LoggerMixin {
  static final _instance = ErrorHandler._();
  ErrorHandler._();

  Future<Result<T>> safeCall<T>(
    Future<T> Function() action, {
    String task = 'Thao tác',
  }) async {
    try {
      log('Bắt đầu: $task');
      final data = await action();
      return Result.success(data);
    } on AppException catch (e) {
      // 1. Bắt các lỗi tự định nghĩa (Custom Exception)
      // Các lỗi này đã có thông báo rõ ràng, an toàn để hiển thị cho người dùng
      log('Lỗi nghiệp vụ: $e');
      return Result.failure(e.message);
    } on FormatException catch (e) {
      // 2. Bắt lỗi định dạng từ hệ thống Dart (ví dụ chuỗi JSON sai cú pháp)
      log('Lỗi định dạng: ${e.message}');
      return Result.failure('Dữ liệu không đúng định dạng JSON');
    } catch (e, stack) {
      // 3. Bắt các lỗi bất ngờ khác (ví dụ truy cập ngoài mảng RangeError, Null...)
      log('Lỗi không xác định: $e\n$stack');
      return Result.failure('Đã có lỗi xảy ra, vui lòng thử lại');
    } finally {
      // 4. Luôn luôn chạy để hoàn tất tác vụ
      log('Kết thúc: $task');
    }
  }
}

/// Hàm tiện ích toàn cục: bọc tác vụ bất đồng bộ qua safeCall
Future<Result<T>> safeCall<T>(
  Future<T> Function() action, {
  String task = 'Thao tác',
}) =>
    ErrorHandler._instance.safeCall(action, task: task);

