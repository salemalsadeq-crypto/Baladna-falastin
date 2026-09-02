import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'details_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String? regionId;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.regionId,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _service.getListings(
      categoryId: widget.categoryId,
      regionId: widget.regionId,
      limit: 50,
    );
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('لا يوجد عناصر بهذا القسم حاليًا'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.clay, AppColors.oliveDeep]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['address_text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DetailsScreen(listing: item)),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
