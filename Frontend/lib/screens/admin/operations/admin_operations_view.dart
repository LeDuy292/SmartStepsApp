import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/auth_service.dart';
import '../../../utils/constants.dart';

class AdminOperationsView extends StatefulWidget {
  const AdminOperationsView({super.key});

  @override
  State<AdminOperationsView> createState() => _AdminOperationsViewState();
}

class _AdminOperationsViewState extends State<AdminOperationsView> {
  late Future<List<dynamic>> _feedback;
  late Future<List<dynamic>> _payments;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _feedback = _get('/api/admin/feedback');
    _payments = _get('/api/admin/premium/payments');
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Vận hành'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Phản hồi'),
            Tab(text: 'Giao dịch'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(children: [_feedbackTab(), _paymentTab()]),
    ),
  );

  Widget _feedbackTab() => FutureBuilder<List<dynamic>>(
    future: _feedback,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return _loadingOrError(snapshot);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: snapshot.data!
            .whereType<Map<String, dynamic>>()
            .map(
              (item) => Card(
                child: ListTile(
                  leading: Icon(
                    item['category'] == 'Bug'
                        ? Icons.bug_report
                        : Icons.feedback,
                  ),
                  title: Text(
                    item['improvementNote']?.toString().isNotEmpty == true
                        ? item['improvementNote'].toString()
                        : 'Không có nội dung',
                  ),
                  subtitle: Text(
                    '${item['fullName']} • ${item['category']} • ${item['status']}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _updateFeedback(item),
                ),
              ),
            )
            .toList(),
      );
    },
  );

  Widget _paymentTab() => FutureBuilder<List<dynamic>>(
    future: _payments,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return _loadingOrError(snapshot);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: snapshot.data!
            .whereType<Map<String, dynamic>>()
            .map(
              (item) => Card(
                child: ListTile(
                  leading: const Icon(Icons.payments),
                  title: Text(
                    '${item['fullName']} • ${item['amount']} ${item['currency']}',
                  ),
                  subtitle: Text(
                    '${item['planCode']} • ${item['status']} • #${item['orderCode']}',
                  ),
                  trailing: item['status'] == 'Paid'
                      ? TextButton(
                          onPressed: () => _refund(item['paymentId'] as int),
                          child: const Text('Hoàn tiền'),
                        )
                      : null,
                ),
              ),
            )
            .toList(),
      );
    },
  );

  Widget _loadingOrError(AsyncSnapshot<List<dynamic>> snapshot) =>
      snapshot.hasError
      ? Center(child: Text('${snapshot.error}'))
      : const Center(child: CircularProgressIndicator());

  Future<void> _updateFeedback(Map<String, dynamic> item) async {
    final response = TextEditingController(
      text: item['adminResponse']?.toString() ?? '',
    );
    String status = item['status']?.toString() ?? 'New';
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Xử lý phản hồi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                items: const ['New', 'Processing', 'Resolved']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => status = value ?? status),
              ),
              TextField(
                controller: response,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Phản hồi của admin',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (submit == true) {
      await _patch('/api/admin/feedback/${item['feedbackId']}', {
        'status': status,
        'adminResponse': response.text,
      });
      if (mounted) setState(_reload);
    }
    response.dispose();
  }

  Future<void> _refund(int paymentId) async {
    await _post('/api/admin/premium/payments/$paymentId/refund');
    if (mounted) setState(_reload);
  }

  Future<List<dynamic>> _get(String path) async {
    final response = await http.get(_uri(path), headers: await _headers());
    _check(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<void> _patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      _uri(path),
      headers: await _headers(json: true),
      body: jsonEncode(body),
    );
    _check(response);
  }

  Future<void> _post(String path) async {
    final response = await http.post(_uri(path), headers: await _headers());
    _check(response);
  }

  Uri _uri(String path) {
    final configured = AppConstants.apiBaseUrl.trim();
    final base = configured.isNotEmpty
        ? configured.replaceFirst(RegExp(r'/$'), '')
        : (kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080');
    return Uri.parse('$base$path');
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await AuthService().getToken();
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API ${response.statusCode}: ${response.body}');
    }
  }
}
