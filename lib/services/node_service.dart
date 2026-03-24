import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NodeConfig {
  String url;
  String user;
  String pass;
  String wallet;

  NodeConfig({this.url = 'http://127.0.0.1:7332', this.user = '', this.pass = '', this.wallet = ''});

  Map<String, dynamic> toJson() => {'url': url, 'user': user, 'pass': pass, 'wallet': wallet};

  factory NodeConfig.fromJson(Map<String, dynamic> json) => NodeConfig(
    url: json['url'] ?? 'http://127.0.0.1:7332',
    user: json['user'] ?? '',
    pass: json['pass'] ?? '',
    wallet: json['wallet'] ?? '',
  );
}

class NodeService {
  static final NodeService instance = NodeService._();
  NodeService._();

  NodeConfig config = NodeConfig();
  bool _connected = false;
  bool get isConnected => _connected;

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('node_config');
    if (json != null) {
      config = NodeConfig.fromJson(jsonDecode(json));
    }
  }

  Future<void> saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('node_config', jsonEncode(config.toJson()));
  }

  Future<dynamic> rpc(String method, [List<dynamic> params = const []]) async {
    final url = config.wallet.isNotEmpty
        ? '${config.url}/wallet/${config.wallet}'
        : config.url;

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (config.user.isNotEmpty) {
      headers['Authorization'] = 'Basic ${base64Encode(utf8.encode('${config.user}:${config.pass}'))}';
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'jsonrpc': '1.0',
          'id': DateTime.now().millisecondsSinceEpoch,
          'method': method,
          'params': params,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception(data['error']['message']);
      }
      _connected = true;
      return data['result'];
    } catch (e) {
      if (e is Exception && e.toString().contains('message')) {
        _connected = true;
        rethrow;
      }
      _connected = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBlockchainInfo() async {
    final result = await rpc('getblockchaininfo');
    return Map<String, dynamic>.from(result);
  }

  Future<double> getBalance() async {
    final result = await rpc('getbalance');
    return (result as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getTransactions([int count = 50]) async {
    final result = await rpc('listtransactions', ['*', count, 0, true]);
    return (result as List).map((t) => Map<String, dynamic>.from(t)).toList().reversed.toList();
  }

  Future<List<Map<String, dynamic>>> getUnspent(List<String> addresses) async {
    final result = await rpc('listunspent', [0, 9999999, addresses]);
    return (result as List).map((u) => Map<String, dynamic>.from(u)).toList();
  }

  Future<void> importAddress(String address) async {
    try {
      await rpc('importaddress', [address, '', false]);
    } catch (_) {}
  }

  Future<String> sendRawTransaction(String hex) async {
    return (await rpc('sendrawtransaction', [hex])).toString();
  }
}
