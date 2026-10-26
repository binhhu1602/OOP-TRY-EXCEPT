import 'dart:convert';

import '../core/exceptions.dart';
import '../core/mixins.dart';
import '../models/product.dart';

// ==========================================
// 5. GENERICS VÀ INTERFACE REPOSITORY
// ==========================================
// Repository<T> là giao diện (interface) chung cho mọi kiểu đối tượng (T).
abstract class Repository<T> {
  List<T> getAll();
  T findById(int id);
  void add(T item);
  bool delete(int id);
}

/// Lớp ProductRepository kế thừa `Repository<Product>`
/// Đồng thời sử dụng 2 Mixin:
/// - LoggerMixin: tự động có hàm log()
/// - ValidatorMixin: tự động có các hàm kiểm tra hợp lệ
class ProductRepository extends Repository<Product> with LoggerMixin, ValidatorMixin {
  final List<Product> _items = [];

  @override
  List<Product> getAll() => List.unmodifiable(_items);

  @override
  Product findById(int id) {
    log('Tìm sản phẩm có mã id = $id');
    return _items.firstWhere(
      (p) => p.id == id,
      orElse: () => throw NotFoundException('Không tìm thấy sản phẩm có mã $id'),
    );
  }

  @override
  void add(Product item) {
    // 1. Kiểm tra tính hợp lệ bằng ValidatorMixin
    requireNotEmpty(item.name, 'Tên sản phẩm');
    requirePositive(item.price, 'Giá');

    // 2. Thêm vào danh sách và ghi log bằng LoggerMixin
    _items.add(item);
    log('Đã thêm sản phẩm: ${item.name} (${item.price.toStringAsFixed(0)}đ)');
  }

  @override
  bool delete(int id) {
    log('Yêu cầu xóa sản phẩm mã id = $id');
    final index = _items.indexWhere((p) => p.id == id);
    if (index == -1) {
      throw NotFoundException('Không thể xóa: Không tìm thấy sản phẩm có mã $id');
    }
    final removed = _items.removeAt(index);
    log('Đã xóa thành công sản phẩm: ${removed.name} (id=$id)');
    return true;
  }

  /// Tạo mới sản phẩm từ chuỗi nhập vào từ giao diện
  Product create(String name, String priceText) {
    // Kiểm tra tên trước
    requireNotEmpty(name, 'Tên sản phẩm');

    // Chuyển đổi và kiểm tra giá
    final price = double.tryParse(priceText);
    if (price == null) {
      throw const ValidationException('Giá sản phẩm phải là một con số hợp lệ');
    }

    // Tự sinh ID tăng dần
    final nextId = _items.isEmpty ? 1 : _items.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    final product = Product(id: nextId, name: name.trim(), price: price);

    add(product);
    return product;
  }

  /// Nạp danh sách sản phẩm từ JSON (áp dụng Factory constructor Product.fromJson)
  Future<int> loadFromJson(String jsonText) async {
    log('Bắt đầu giải mã chuỗi JSON');
    await Future.delayed(const Duration(milliseconds: 250)); // Giả lập độ trễ mạng nhẹ

    // jsonDecode có thể ném FormatException nếu chuỗi JSON sai cú pháp
    final dynamic decoded = jsonDecode(jsonText);

    if (decoded is! List) {
      throw const ParseException('Dữ liệu JSON phải là một danh sách các sản phẩm ([...])');
    }

    // Sử dụng Factory Constructor Product.fromJson để chuyển từng phần tử Map sang Product
    final products = decoded.map((e) {
      if (e is! Map<String, dynamic>) {
        throw const ParseException('Mỗi phần tử trong danh sách phải là một đối tượng JSON');
      }
      return Product.fromJson(e);
    }).toList();

    _items
      ..clear()
      ..addAll(products);

    log('Đã nạp thành công ${products.length} sản phẩm từ JSON');
    return products.length;
  }

  /// Xóa toàn bộ danh sách
  void clearAll() {
    _items.clear();
    log('Đã dọn sạch toàn bộ danh sách sản phẩm');
  }
}

