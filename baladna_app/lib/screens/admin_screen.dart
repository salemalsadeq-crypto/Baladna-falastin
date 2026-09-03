import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _service.getPendingListings();
    setState(() {
      _pending = items;
      _loading = false;
    });
  }

  Future<void> _approve(String id) async {
    await _service.approveListing(id);
    _load();
  }

  Future<void> _reject(String id) async {
    await _service.rejectListing(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة العناصر الجديدة')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _pending.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('لا يوجد عناصر قيد المراجعة حاليا')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pending.length,
                    itemBuilder: (context, index) {
                      final item = _pending[index];
                      final cat = item['categories'];
                      final reg = item['regions'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                              '${cat?['icon'] ?? ''} ${cat?['name_ar'] ?? ''}  ·  ${reg?['name_ar'] ?? ''}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(item['description'], style: const TextStyle(fontSize: 13)),
                            ],
                            if (item['phone'] != null && item['phone'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('هاتف: ${item['phone']}', style: const TextStyle(fontSize: 12)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approve(item['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.ok,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('موافقة'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _reject(item['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.clay,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('رفض'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
