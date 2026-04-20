import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print("Loging in...");
  final res1 = await http.post(
    Uri.parse('http://localhost:8000/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"ten_dang_nhap": "shipper_test_auto_002", "mat_khau": "shipper123"}), // A valid login
  );
  
  if (res1.statusCode != 200) {
    print("Login failed: \${res1.body}");
    return;
  }
  
  final token = jsonDecode(utf8.decode(res1.bodyBytes))['token'];
  
  print("Fetching available orders...");
  final res2 = await http.get(
    Uri.parse('http://localhost:8000/api/shipper/orders/available'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer \$token',
    }
  );
  
  if (res2.statusCode != 200) {
    print("API failed \${res2.statusCode}: \${res2.body}");
    return;
  }
  
  final data = jsonDecode(utf8.decode(res2.bodyBytes));
  try {
    final items = (data['items'] ?? []) as List<dynamic>;
    final ids = items.map((o) => o['ma_don_hang']?.toString() ?? '').toSet();
    print("Success: retrieved \${items.length} items. ids: \$ids");
  } catch (e, stack) {
    print("Dart parse error: \$e");
    print(stack);
  }
}
