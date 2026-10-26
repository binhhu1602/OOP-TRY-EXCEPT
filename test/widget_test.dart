import 'package:flutter_app/core/exceptions.dart';
import 'package:flutter_app/core/safe_call.dart';
import 'package:flutter_app/data/repository.dart';
import 'package:flutter_app/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Factory fromJson tạo đúng Product', () {
    final p = Product.fromJson({'id': 1, 'name': 'Bút', 'price': 5000});
    expect(p.name, 'Bút');
    expect(p.price, 5000.0);
  });

  test('Factory fromJson ném ParseException khi thiếu trường', () {
    expect(() => Product.fromJson({'id': 1, 'name': 'Bút'}), throwsA(isA<ParseException>()));
  });

  test('Validator mixin chặn giá âm', () {
    final repo = ProductRepository();
    expect(() => repo.create('Bút', '-1'), throwsA(isA<ValidationException>()));
  });

  test('safeCall đổi lỗi thành thông báo thân thiện, không crash', () async {
    final repo = ProductRepository();
    final notFound = await safeCall(() async => repo.findById(999));
    expect(notFound.isSuccess, false);
    expect(notFound.error, 'Không tìm thấy sản phẩm có mã 999');

    final broken = await safeCall(() => repo.loadFromJson('[{'));
    expect(broken.error, 'Dữ liệu không đúng định dạng JSON');

    final unexpected = await safeCall<int>(() async => <int>[][5]);
    expect(unexpected.error, 'Đã có lỗi xảy ra, vui lòng thử lại');
  });
}
