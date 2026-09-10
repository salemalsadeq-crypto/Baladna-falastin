import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class GovernoratesScreen extends StatefulWidget {
  const GovernoratesScreen({super.key});

  @override
  State<GovernoratesScreen> createState() => _GovernoratesScreenState();
}

class _GovernoratesScreenState extends State<GovernoratesScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _regions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final regions = await _service.getGovernorates();
    setState(() {
      _regions = regions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sandLight,
      appBar: AppBar(title: const Text('المحافظات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context, null),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.oliveDeep,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.public, color: Colors.white),
                        SizedBox(width: 12),
                        Text('كل المحافظات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                ..._regions.map((r) => InkWell(
                      onTap: () => Navigator.pop(context, r),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.clay),
                            const SizedBox(width: 12),
                            Text(r['name_ar'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
