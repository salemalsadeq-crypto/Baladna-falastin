import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'category_screen.dart';
import 'add_listing_screen.dart';
import 'admin_screen.dart';
import 'search_screen.dart';

// غيّر هذا الرمز لأي رقم سري تحبه، هو مفتاح الدخول للوحة الإدارة
const String _adminPin = '5522';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = SupabaseService();

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _nearby = [];
  Map<String, dynamic>? _selectedRegion;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final regions = await _service.getGovernorates();
      final categories = await _service.getCategories();
      final nearby = await _service.getListings(limit: 10);
      setState(() {
        _regions = regions;
        _categories = categories;
        _nearby = nearby;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onRegionSelected(Map<String, dynamic>? region) async {
    setState(() => _selectedRegion = region);
    try {
      final nearby = await _service.getListings(regionId: region?['id'], limit: 10);
      setState(() => _nearby = nearby);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _openAdminLogin() {
    final pinController = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('دخول الإدارة'),
              content: TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'أدخل الرمز السري',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (pinController.text == _adminPin) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminScreen()),
                      );
                    } else {
                      setDialogState(() => errorText = 'رمز غير صحيح');
                    }
                  },
                  child: const Text('دخول'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بلدنا فلسطين 🇵🇸'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'دخول الإدارة',
            onPressed: _openAdminLogin,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.clay,
        icon: const Icon(Icons.add),
        label: const Text('أضف نشاطك'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddListingScreen()),
          );
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadInitial,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.oliveDeep, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInitial,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.sand),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('ابحث عن محل، خدمة، إعلان...', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.sand),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Map<String, dynamic>?>(
                            isExpanded: true,
                            hint: const Text('📍 كل المحافظات'),
                            value: _selectedRegion,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('📍 كل المحافظات')),
                              ..._regions.map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text('📍 ${r['name_ar']}'),
                                  )),
                            ],
                            onChanged: _onRegionSelected,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('الأقسام',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                        children: _categories.map((cat) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CategoryScreen(
                                    categoryId: cat['id'],
                                    categoryName: cat['name_ar'],
                                    regionId: _selectedRegion?['id'],
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.sand,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(cat['icon'] ?? '', style: const TextStyle(fontSize: 24)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name_ar'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        _selectedRegion == null ? 'أحدث الإضافات' : 'أحدث الإضافات في ${_selectedRegion!['name_ar']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.oliveDeep),
                      ),
                      const SizedBox(height: 10),
                      if (_nearby.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('لا يوجد عناصر بعد بهذه المنطقة', style: TextStyle(color: Colors.grey)),
                        ),
                      ..._nearby.map((item) => _ListingCard(item: item)),
                    ],
                  ),
                ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ListingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.olive, AppColors.oliveDeep]),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                if (item['description'] != null)
                  Text(
                    item['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
