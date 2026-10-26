import '../core/exceptions.dart';

class Product {
  final int id;
  final String name;
  final double price;

  // Constructor mặc định
  const Product({required this.id, required this.name, required this.price});

  // ===== NAMED CONSTRUCTOR =====
  // Tạo sản phẩm "rỗng" làm giá trị mặc định.
  const Product.empty() : id = 0, name = 'Chưa đặt tên', price = 0;

  // ===== FACTORY CONSTRUCTOR =====
  // Factory có thể chạy logic trước khi tạo đối tượng: kiểm tra, chuyển kiểu,
  // hoặc ném lỗi. Ở đây dùng để chuyển Map/JSON -> Product.
  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final price = json['price'];

    if (id is! int) {
      throw ParseException('Sản phẩm thiếu mã (id) hợp lệ', details: 'id=$id');
    }
    if (name is! String || name.trim().isEmpty) {
      throw ParseException('Sản phẩm #$id thiếu tên', details: 'name=$name');
    }
    if (price is! num) {
      throw ParseException('Giá của "$name" không phải là số', details: 'price=$price');
    }
    return Product(id: id, name: name.trim(), price: price.toDouble());
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price)';
}
