import 'dart:convert';

import '../core/exceptions.dart';
import '../core/mixins.dart';
import '../models/product.dart';

// ===== GENERICS =====
// Repository<T> là khuôn chung cho mọi loại dữ liệu (Product, User...).
abstract class Repository<T> {
  List<T> getAll();
  T findById(int id);
  void add(T item);
}

// ProductRepository dùng 2 mixin: tự ghi log + kiểm tra hợp lệ.
class ProductRepository extends Repository<Product> with LoggerMixin, ValidatorMixin {
  final List<Product> _items = [];

  @override
  List<Product> getAll() => List.unmodifiable(_items);

  @override
  Product findById(int id) {
    log('Tìm sản phẩm id=$id');
    return _items.firstWhere(
      (p) => p.id == id,
      orElse: () => throw NotFoundException('Không tìm thấy sản phẩm có mã $id'),
    );
  }

  @override
  void add(Product item) {
    requireNotEmpty(item.name, 'Tên sản phẩm'); // từ ValidatorMixin
    requirePositive(item.price, 'Giá'); // từ ValidatorMixin
    _items.add(item);
    log('Đã thêm $item'); // từ LoggerMixin
  }

  /// Tạo sản phẩm mới từ dữ liệu người dùng nhập.
  Product create(String name, String priceText) {
    requireNotEmpty(name, 'Tên sản phẩm');
    final price = double.tryParse(priceText);
    if (price == null) throw const ValidationException('Giá phải là một con số');
    final nextId = _items.isEmpty ? 1 : _items.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    final product = Product(id: nextId, name: name, price: price);
    add(product);
    return product;
  }

  /// Nạp danh sách sản phẩm từ chuỗi JSON (dùng factory Product.fromJson).
  Future<int> loadFromJson(String jsonText) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Giả lập gọi API
    final decoded = jsonDecode(jsonText); // Có thể ném FormatException
    if (decoded is! List) {
      throw const ParseException('Dữ liệu phải là một danh sách sản phẩm');
    }
    final products = decoded.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    _items
      ..clear()
      ..addAll(products);
    log('Đã nạp ${products.length} sản phẩm từ JSON');
    return products.length;
  }
}
