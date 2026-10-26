import '../core/exceptions.dart';

/// Lớp đối tượng Product (Sản phẩm)
/// Minh họa: Constructor mặc định, Named constructor và Factory constructor
class Product {
  final int id;
  final String name;
  final double price;

  // 1. Constructor mặc định (Generative Constructor)
  const Product({
    required this.id,
    required this.name,
    required this.price,
  });

  // 2. Named Constructor: Khởi tạo với giá trị mặc định cho sản phẩm rỗng
  const Product.empty()
      : id = 0,
        name = 'Chưa đặt tên',
        price = 0.0;

  // 3. Factory Constructor: Chuyển đổi dữ liệu từ Map / JSON
  // Có thể kiểm tra tính hợp lệ trước khi tạo đối tượng và ném ngoại lệ nếu sai
  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final price = json['price'];

    // Kiểm tra và ném Custom Exception nếu dữ liệu sai/thiếu
    if (id is! int) {
      throw ParseException('Sản phẩm thiếu mã (id) hợp lệ', details: 'id=$id');
    }
    if (name is! String || name.trim().isEmpty) {
      throw ParseException('Sản phẩm #$id thiếu tên', details: 'name=$name');
    }
    if (price is! num) {
      throw ParseException('Giá của "$name" không phải là số', details: 'price=$price');
    }

    return Product(
      id: id,
      name: name.trim(),
      price: price.toDouble(),
    );
  }

  // Chuyển đối tượng thành Map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };

  @override
  String toString() => 'Product(id: $id, name: "$name", price: ${price.toStringAsFixed(0)}đ)';
}

