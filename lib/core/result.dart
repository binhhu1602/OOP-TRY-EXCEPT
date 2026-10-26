// ==========================================
// 3. GENERICS CƠ BẢN TRONG DART
// ==========================================
// Result<T> là một class tổng quát (Generic Class), với <T> là kiểu dữ liệu linh hoạt.
// T có thể là Product, List<Product>, int, String... tùy trường hợp.
//
// Kết hợp Named Constructor:
// - Result.success(data): khi thao tác thành công, chứa dữ liệu T
// - Result.failure(error): khi thao tác thất bại, chứa thông báo lỗi cho người dùng
class Result<T> {
  final T? data;
  final String? error;

  const Result.success(this.data) : error = null; // Named constructor thành công
  const Result.failure(this.error) : data = null; // Named constructor thất bại

  bool get isSuccess => error == null;
}

