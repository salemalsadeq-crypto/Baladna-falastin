import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'edit_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getMyListings();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف النشاط'),
        content: const Text('متأكد إنك تبي تحذف هذا النشاط نهائيًا؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.clay)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deleteListing(id);
        _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = AppColors.ok;
        label = 'معتمد';
        break;
      case 'rejected':
        color = AppColors.clay;
        label = 'مرفوض';
        break;
      default:
        color = AppColors.gold;
        label = 'قيد المراجعة';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sandLight,
      appBar: AppBar(title: const Text('أنشطتي')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                        ],
                      ),
                    ),
                  )
                : _items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(child: Text('لسا ما أضفت أي نشاط', style: TextStyle(color: Colors.grey))),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final cat = item['categories'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(item['title'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ),
                                    _statusBadge(item['status']),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${cat?['icon'] ?? ''} ${cat?['name_ar'] ?? ''}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => EditListingScreen(listing: item)),
                                          );
                                          _load();
                                        },
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('تعديل'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _delete(item['id']),
                                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.clay),
                                        label: const Text('حذف', style: TextStyle(color: AppColors.clay)),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.clay)),
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
