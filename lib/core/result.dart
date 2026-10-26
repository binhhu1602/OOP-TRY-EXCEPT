// ===== GENERICS =====
// Result<T> là "hộp" chứa kết quả của một thao tác:
// thành công thì có `data` kiểu T, thất bại thì có `error` (thông báo).
// T có thể là bất kỳ kiểu nào: Product, List<Product>, int...
class Result<T> {
  final T? data;
  final String? error;

  const Result.success(this.data) : error = null; // Named constructor
  const Result.failure(this.error) : data = null; // Named constructor

  bool get isSuccess => error == null;
}
