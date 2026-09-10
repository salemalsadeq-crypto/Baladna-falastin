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
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _service.getPendingListings();
    final stats = await _service.getAdminStats();
    setState(() {
      _pending = items;
      _stats = stats;
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

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة العناصر الجديدة')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_stats != null) ...[
                    Row(
                      children: [
                        _statBox('المستخدمين', '${_stats!['totalUsers']}', AppColors.oliveDeep),
                        _statBox('الأنشطة', '${_stats!['totalListings']}', AppColors.oliveDeep),
                        _statBox('المشاهدات', '${_stats!['totalViews']}', AppColors.oliveDeep),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statBox('قيد المراجعة', '${_stats!['pending']}', AppColors.gold),
                        _statBox('معتمد', '${_stats!['approved']}', AppColors.ok),
                        _statBox('مرفوض', '${_stats!['rejected']}', AppColors.clay),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text('بانتظار المراجعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (_pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: Text('لا يوجد عناصر قيد المراجعة حاليا')),
                    )
                  else
                    ..._pending.map((item) {
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
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.ok, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('موافقة'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _reject(item['id']),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.clay, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('رفض'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
