import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _service.getNotifications();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sandLight,
      appBar: AppBar(title: const Text('الإشعارات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('لا يوجد إشعارات بعد', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final n = _items[index];
                    final isRead = n['is_read'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : AppColors.sand,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5)],
                      ),
                      child: InkWell(
                        onTap: () async {
                          if (!isRead) {
                            await _service.markNotificationRead(n['id']);
                            _load();
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            if (n['body'] != null) ...[
                              const SizedBox(height: 4),
                              Text(n['body'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
