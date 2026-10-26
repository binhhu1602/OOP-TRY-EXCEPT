import 'package:flutter/material.dart';

import 'core/mixins.dart';
import 'core/result.dart';
import 'core/safe_call.dart';
import 'data/repository.dart';
import 'models/product.dart';

void main() => runApp(const ProductApp());

// ==========================================
// DỮ LIỆU MẪU ĐỂ MINH HỌA
// ==========================================
const sampleValidJson = '''
[
  {"id": 1, "name": "Bàn phím cơ Gaming", "price": 850000},
  {"id": 2, "name": "Chuột không dây Logitech", "price": 350000},
  {"id": 3, "name": "Tai nghe chống ồn Sony", "price": 1250000}
]''';

const sampleMissingFieldJson = '''
[
  {"id": 4, "name": "Màn hình 27 inch 2K"}
]'''; // Thiếu trường "price"

const sampleBrokenJson = '[{"id": 5, "name": "Loa Bluetooth", '; // Thiếu dấu đóng mảng/ngoặc

class ProductApp extends StatelessWidget {
  const ProductApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Dữ Liệu OOP & Xử Lý Lỗi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ProductHomePage(),
    );
  }
}

class ProductHomePage extends StatefulWidget {
  const ProductHomePage({super.key});

  @override
  State<ProductHomePage> createState() => _ProductHomePageState();
}

class _ProductHomePageState extends State<ProductHomePage> {
  final ProductRepository _repo = ProductRepository();

  // Controller nhập liệu
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _searchIdCtrl = TextEditingController();

  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = true;

  @override
  void initState() {
    super.initState();
    // Nạp sẵn dữ liệu mẫu khi khởi động để người dùng thấy danh sách ngay
    _loadInitialData();
  }

  void _loadInitialData() {
    _repo.loadFromJson(sampleValidJson);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _searchIdCtrl.dispose();
    super.dispose();
  }

  /// Hàm điều phối trung tâm:
  /// Bọc hành động qua safeCall() -> Áp dụng cấu trúc try-catch-finally,
  /// tự động ghi log qua LoggerMixin và trả về thông báo thân thiện cho người dùng.
  Future<void> _executeTask<T>({
    required String taskName,
    required Future<T> Function() action,
    required String Function(T data) onSuccessMessage,
  }) async {
    setState(() => _isLoading = true);

    // Kỹ thuật xử lý lỗi an toàn: Không làm sập ứng dụng khi có Exception
    final Result<T> result = await safeCall<T>(action, task: taskName);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccess = result.isSuccess;
      if (result.isSuccess) {
        _statusMessage = onSuccessMessage(result.data as T);
      } else {
        _statusMessage = result.error ?? 'Đã xảy ra lỗi không mong muốn';
      }
    });

    // Thông báo nhanh qua SnackBar
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_statusMessage!),
          backgroundColor: _isSuccess ? Colors.teal.shade700 : Colors.red.shade700,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // Thao tác: Thêm sản phẩm mới (ValidatorMixin kiểm tra tính hợp lệ)
  void _addProduct() {
    _executeTask(
      taskName: 'Thêm sản phẩm mới',
      action: () async => _repo.create(_nameCtrl.text, _priceCtrl.text),
      onSuccessMessage: (Product p) {
        _nameCtrl.clear();
        _priceCtrl.clear();
        return 'Đã thêm thành công: "${p.name}" (${p.price.toStringAsFixed(0)}đ)';
      },
    );
  }

  // Thao tác: Tìm kiếm sản phẩm theo ID (Ném NotFoundException nếu không có)
  void _searchProduct() {
    final idText = _searchIdCtrl.text.trim();
    if (idText.isEmpty) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Vui lòng nhập mã ID để tìm kiếm';
      });
      return;
    }
    final id = int.tryParse(idText);
    if (id == null) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Mã ID phải là một số nguyên';
      });
      return;
    }

    _executeTask(
      taskName: 'Tìm kiếm sản phẩm ID=$id',
      action: () async => _repo.findById(id),
      onSuccessMessage: (Product p) => 'Tìm thấy: "${p.name}" - Giá: ${p.price.toStringAsFixed(0)}đ',
    );
  }

  // Thao tác: Xóa sản phẩm theo ID
  void _deleteProduct(int id) {
    _executeTask(
      taskName: 'Xóa sản phẩm ID=$id',
      action: () async => _repo.delete(id),
      onSuccessMessage: (_) => 'Đã xóa thành công sản phẩm có mã ID = $id',
    );
  }

  // Thao tác: Điền dữ liệu mẫu vào ô nhập
  void _fillSampleInput() {
    setState(() {
      _nameCtrl.text = 'Tai nghe Gaming RGB';
      _priceCtrl.text = '650000';
    });
  }

  // Hiển thị hộp thoại nhật ký (LoggerMixin)
  void _showLogsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) {
              final logs = LoggerMixin.logs;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.terminal, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text(
                              'Nhật ký hệ thống (LoggerMixin)',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Xóa nhật ký',
                          icon: const Icon(Icons.delete_sweep, color: Colors.red),
                          onPressed: () {
                            setState(() => LoggerMixin.clearLogs());
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: logs.isEmpty
                          ? const Center(child: Text('Chưa có dòng log nào.'))
                          : Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final line = logs[index];
                                  Color textColor = Colors.greenAccent;
                                  if (line.contains('Lỗi') || line.contains('Exception')) {
                                    textColor = Colors.redAccent;
                                  } else if (line.contains('Bắt đầu') || line.contains('Kết thúc')) {
                                    textColor = Colors.cyanAccent;
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      line,
                                      style: TextStyle(
                                        color: textColor,
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _repo.getAll();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Quản Lý Sản Phẩm',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 2,
          actions: [
            // Nút mở nhật ký LoggerMixin
            IconButton(
              tooltip: 'Xem nhật ký (LoggerMixin)',
              icon: Badge(
                label: Text('${LoggerMixin.logs.length}'),
                child: const Icon(Icons.receipt_long),
              ),
              onPressed: _showLogsDialog,
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Column(
              children: [
                if (_isLoading) const LinearProgressIndicator(minHeight: 3),
                const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.inventory_2_outlined),
                      text: 'Quản Lý Sản Phẩm',
                    ),
                    Tab(
                      icon: Icon(Icons.science_outlined),
                      text: 'Thử Nghiệm OOP & Lỗi',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            // Hộp hiển thị thông báo trạng thái trực quan
            if (_statusMessage != null) _buildStatusBanner(),

            // Nội dung theo Tab
            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1: Giao diện quản lý thông thường
                  _buildManagementTab(products),

                  // TAB 2: Các nút demo các khái niệm OOP & Xử lý ngoại lệ
                  _buildDemoLabTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Khung hiển thị thông báo thân thiện (Friendly error / success banner)
  Widget _buildStatusBanner() {
    final bgColor = _isSuccess ? Colors.green.shade50 : Colors.red.shade50;
    final borderColor = _isSuccess ? Colors.green.shade300 : Colors.red.shade300;
    final textColor = _isSuccess ? Colors.green.shade900 : Colors.red.shade900;
    final icon = _isSuccess ? Icons.check_circle_outline : Icons.error_outline;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isSuccess ? 'Thao tác thành công' : 'Thông báo lỗi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
                Text(
                  _statusMessage!,
                  style: TextStyle(fontSize: 14, color: textColor),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: textColor),
            onPressed: () => setState(() => _statusMessage = null),
          ),
        ],
      ),
    );
  }

  /// ==========================================
  /// TAB 1: QUẢN LÝ SẢN PHẨM (DỄ DÙNG)
  /// ==========================================
  Widget _buildManagementTab(List<Product> products) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card 1: Thêm sản phẩm mới
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thêm Sản Phẩm Mới',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: _fillSampleInput,
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Điền mẫu', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm',
                    hintText: 'Ví dụ: Bàn phím cơ',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá bán (VNĐ)',
                    hintText: 'Ví dụ: 850000',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm Sản Phẩm (Áp dụng ValidatorMixin)'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Card 2: Tra cứu & Xóa theo ID
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tra Cứu / Xóa Theo Mã ID',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchIdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nhập mã ID',
                          hintText: 'VD: 1, 2, 999...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _searchProduct,
                      child: const Text('Tìm'),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        final id = int.tryParse(_searchIdCtrl.text.trim());
                        if (id != null) {
                          _deleteProduct(id);
                        } else {
                          setState(() {
                            _isSuccess = false;
                            _statusMessage = 'Vui lòng nhập ID hợp lệ để xóa';
                          });
                        }
                      },
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Danh sách sản phẩm
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh Sách Sản Phẩm (${products.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (products.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() => _repo.clearAll());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã làm trống danh sách')),
                  );
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Xóa tất cả'),
              ),
          ],
        ),

        const SizedBox(height: 8),

        if (products.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'Danh sách hiện đang trống',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    _executeTask(
                      taskName: 'Nạp lại dữ liệu mẫu',
                      action: () async => _repo.loadFromJson(sampleValidJson),
                      onSuccessMessage: (n) => 'Đã nạp $n sản phẩm mẫu thành công',
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Nạp lại dữ liệu mẫu'),
                ),
              ],
            ),
          )
        else
          ...products.map(
            (p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade50,
                  foregroundColor: Colors.indigo,
                  child: Text('${p.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('ID: ${p.id}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${p.price.toStringAsFixed(0)} đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Xóa sản phẩm này',
                      onPressed: () => _deleteProduct(p.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// ==========================================
  /// TAB 2: PHÒNG THỬ NGHIỆM OOP & XỬ LÝ LỖI
  /// ==========================================
  Widget _buildDemoLabTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Giới thiệu
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.indigo),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bấm vào các nút bên dưới để kiểm tra trực tiếp cơ chế hoạt động của OOP và xử lý ngoại lệ (try-catch-finally).',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 1. Factory Constructor (FromJson)
        _buildDemoCard(
          title: '1. Factory Constructor: Product.fromJson',
          description: 'Khởi tạo đối tượng từ JSON Map, tự động kiểm tra định dạng và thiếu trường.',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _executeTask(
                taskName: 'Nạp JSON hợp lệ',
                action: () async => _repo.loadFromJson(sampleValidJson),
                onSuccessMessage: (n) => 'Thành công: Đã nạp $n sản phẩm qua Factory constructor',
              ),
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text('JSON hợp lệ'),
            ),
            OutlinedButton.icon(
              onPressed: () => _executeTask(
                taskName: 'Nạp JSON thiếu trường',
                action: () async => _repo.loadFromJson(sampleMissingFieldJson),
                onSuccessMessage: (n) => 'Đã nạp $n',
              ),
              icon: const Icon(Icons.warning_amber, color: Colors.orange),
              label: const Text('Thử JSON thiếu trường (ParseException)'),
            ),
            OutlinedButton.icon(
              onPressed: () => _executeTask(
                taskName: 'Nạp JSON sai cú pháp',
                action: () async => _repo.loadFromJson(sampleBrokenJson),
                onSuccessMessage: (n) => 'Đã nạp $n',
              ),
              icon: const Icon(Icons.code_off, color: Colors.red),
              label: const Text('Thử JSON sai cú pháp (FormatException)'),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 2. Mixin: ValidatorMixin
        _buildDemoCard(
          title: '2. Mixin: ValidatorMixin (Kiểm tra hợp lệ)',
          description: 'Tái sử dụng các hàm kiểm tra logic mà không cần quan hệ kế thừa.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => _executeTask(
                taskName: 'Thử nhập giá âm',
                action: () async => _repo.create('Sản phẩm thử', '-50000'),
                onSuccessMessage: (p) => 'Tạo thành công ${p.name}',
              ),
              icon: const Icon(Icons.money_off, color: Colors.red),
              label: const Text('Thử nhập Giá âm (-50.000đ)'),
            ),
            OutlinedButton.icon(
              onPressed: () => _executeTask(
                taskName: 'Thử để tên rỗng',
                action: () async => _repo.create('   ', '100000'),
                onSuccessMessage: (p) => 'Tạo thành công ${p.name}',
              ),
              icon: const Icon(Icons.space_bar, color: Colors.red),
              label: const Text('Thử để Tên sản phẩm trống'),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 3. Custom Exception: NotFoundException
        _buildDemoCard(
          title: '3. Custom Exception: NotFoundException',
          description: 'Ngoại lệ tự định nghĩa kế thừa AppException, mang thông báo thân thiện.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => _executeTask(
                taskName: 'Tìm ID không tồn tại (999)',
                action: () async => _repo.findById(999),
                onSuccessMessage: (p) => 'Tìm thấy ${p.name}',
              ),
              icon: const Icon(Icons.search_off, color: Colors.orange),
              label: const Text('Tìm sản phẩm ID 999 (NotFoundException)'),
            ),
            OutlinedButton.icon(
              onPressed: () => _executeTask<int>(
                taskName: 'Mô phỏng lỗi hệ thống bất ngờ',
                action: () async => <int>[][10], // RangeError
                onSuccessMessage: (val) => '$val',
              ),
              icon: const Icon(Icons.bug_report, color: Colors.purple),
              label: const Text('Mô phỏng lỗi bất ngờ (RangeError)'),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 4. Named Constructor: Product.empty()
        _buildDemoCard(
          title: '4. Named Constructor: Product.empty()',
          description: 'Khởi tạo đối tượng linh hoạt với các tham số mặc định được đặt tên riêng.',
          actions: [
            FilledButton.tonalIcon(
              onPressed: () {
                const emptyProduct = Product.empty();
                setState(() {
                  _isSuccess = true;
                  _statusMessage = 'Đã tạo: $emptyProduct (ID=${emptyProduct.id}, Giá=${emptyProduct.price})';
                });
                LoggerMixin.logs.insert(
                  0,
                  '[${DateTime.now().toIso8601String().substring(11, 19)}] [NamedConstructor] Khởi tạo Product.empty() -> $emptyProduct',
                );
              },
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Tạo thử Product.empty()'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoCard({
    required String title,
    required String description,
    required List<Widget> actions,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
