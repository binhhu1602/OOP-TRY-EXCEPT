import 'package:flutter/material.dart';

import 'core/mixins.dart';
import 'core/result.dart';
import 'core/safe_call.dart';
import 'data/repository.dart';
import 'models/product.dart';

void main() => runApp(const ProductApp());

// Dữ liệu mẫu để demo các tình huống
const validJson = '''
[
  {"id": 1, "name": "Bàn phím cơ", "price": 850000},
  {"id": 2, "name": "Chuột không dây", "price": 320000},
  {"id": 3, "name": "Tai nghe", "price": 1200000}
]''';
const missingFieldJson = '[{"id": 1, "name": "Màn hình"}, {"id": 2, "price": 500}]';
const brokenJson = '[{"id": 1, "name": "Loa", '; // Thiếu dấu đóng

class ProductApp extends StatelessWidget {
  const ProductApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý sản phẩm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const ProductPage(),
    );
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _repo = ProductRepository();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String? _error; // Lỗi hiện tại để hiển thị lên giao diện
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Mọi nút bấm đều đi qua hàm này: gọi safeCall rồi cập nhật giao diện.
  Future<void> _run<T>(String task, Future<T> Function() action, String Function(T data) onSuccess) async {
    setState(() => _loading = true);
    final Result<T> result = await safeCall(action, task: task);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result.error;
    });
    final message = result.isSuccess ? onSuccess(result.data as T) : result.error!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ));
  }

  void _addProduct() => _run(
        'Thêm sản phẩm',
        () async => _repo.create(_nameController.text, _priceController.text),
        (Product p) {
          _nameController.clear();
          _priceController.clear();
          return 'Đã thêm "${p.name}"';
        },
      );

  @override
  Widget build(BuildContext context) {
    final products = _repo.getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        bottom: _loading ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator()) : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ----- Khung báo lỗi thân thiện -----
          if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(_error!),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _error = null),
                ),
              ),
            ),

          // ----- Các nút demo -----
          const _SectionTitle('1. Nạp dữ liệu JSON (Factory constructor)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => _run('Nạp JSON hợp lệ', () => _repo.loadFromJson(validJson), (n) => 'Đã nạp $n sản phẩm'),
                child: const Text('JSON hợp lệ'),
              ),
              OutlinedButton(
                onPressed: () => _run('Nạp JSON thiếu trường', () => _repo.loadFromJson(missingFieldJson), (n) => 'Đã nạp $n'),
                child: const Text('JSON thiếu trường'),
              ),
              OutlinedButton(
                onPressed: () => _run('Nạp JSON sai cú pháp', () => _repo.loadFromJson(brokenJson), (n) => 'Đã nạp $n'),
                child: const Text('JSON sai cú pháp'),
              ),
            ],
          ),

          const _SectionTitle('2. Thêm sản phẩm (Validator Mixin)'),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _addProduct, child: const Text('Thêm')),
            ],
          ),

          const _SectionTitle('3. Các lỗi khác'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _run('Tìm sản phẩm', () async => _repo.findById(999), (Product p) => 'Tìm thấy ${p.name}'),
                child: const Text('Tìm mã 999'),
              ),
              OutlinedButton(
                onPressed: () => _run<int>('Lỗi bất ngờ', () async => <int>[][5], (n) => '$n'), // RangeError
                child: const Text('Gây lỗi bất ngờ'),
              ),
            ],
          ),

          // ----- Danh sách sản phẩm -----
          _SectionTitle('Danh sách sản phẩm (${products.length})'),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Chưa có sản phẩm. Hãy bấm "JSON hợp lệ" hoặc thêm mới.'),
            ),
          for (final p in products)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${p.id}')),
                title: Text(p.name),
                trailing: Text('${p.price.toStringAsFixed(0)} đ'),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Ví dụ named constructor: Product.empty()'),
              subtitle: Text('${const Product.empty()}'),
            ),
          ),

          // ----- Nhật ký từ LoggerMixin -----
          const _SectionTitle('Nhật ký (Logger Mixin)'),
          Container(
            height: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
            child: ListView(
              children: [
                for (final line in LoggerMixin.logs)
                  Text(line, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
