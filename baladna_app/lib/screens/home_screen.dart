import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'category_screen.dart';
import 'add_listing_screen.dart';
import 'admin_screen.dart';
import 'search_screen.dart';
import 'auth_screen.dart';
import 'account_screen.dart';
import 'governorates_screen.dart';
import 'notifications_screen.dart';

const String _adminPin = '5522';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = SupabaseService();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _nearby = [];
  Map<String, dynamic>? _selectedRegion;
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

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
      final unread = await _service.getUnreadNotificationsCount();
      setState(() {
        _regions = regions;
        _categories = categories;
        _nearby = nearby;
        _unreadCount = unread;
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _goSearch() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  void _openAdminLogin() {
    final pinController = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('دخول الإدارة'),
            content: TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(hintText: 'أدخل الرمز السري', errorText: errorText),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  if (pinController.text == _adminPin) {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                  } else {
                    setDialogState(() => errorText = 'رمز غير صحيح');
                  }
                },
                child: const Text('دخول'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _openAccount() async {
    if (_service.currentUser == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
    }
    setState(() {});
    _loadInitial();
  }

  Future<void> _openNotifications() async {
    if (_service.currentUser == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sandLight,
      appBar: AppBar(
        title: const Text('بلدنا فلسطين 🇵🇸'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'الإشعارات',
                onPressed: _openNotifications,
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: AppColors.clay, shape: BoxShape.circle),
                    child: Text('$_unreadCount', style: const TextStyle(fontSize: 9, color: Colors.white)),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(_service.currentUser == null ? Icons.person_outline : Icons.person),
            tooltip: 'حسابي',
            onPressed: _openAccount,
          ),
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
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingScreen()));
          _loadInitial();
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
                    padding: EdgeInsets.zero,
                    children: [
                      // ===== البانر الترحيبي =====
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.oliveDeep, AppColors.olive],
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text('🇵🇸 كل فلسطين في مكان واحد',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('محلات، عقارات، سيارات، وظائف، خدمات وإعلانات',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                              child: TextField(
                                controller: _searchCtrl,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _goSearch(),
                                decoration: const InputDecoration(
                                  hintText: 'ماذا تبحث في فلسطين؟',
                                  prefixIcon: Icon(Icons.search),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _goSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.ink,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('بحث', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== اختيار المحافظة =====
                            InkWell(
                              onTap: () async {
                                final selected = await Navigator.push<Map<String, dynamic>>(
                                  context,
                                  MaterialPageRoute(builder: (_) => const GovernoratesScreen()),
                                );
                                if (selected != null) _onRegionSelected(selected);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.sand),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: AppColors.clay),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedRegion == null ? 'كل المحافظات' : _selectedRegion!['name_ar'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (_selectedRegion != null)
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () => _onRegionSelected(null),
                                      ),
                                    const Icon(Icons.chevron_left, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),

                            // ===== استكشف الأقسام =====
                            const Text('استكشف الأقسام',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                            const SizedBox(height: 14),
                            ..._categories.map((cat) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
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
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(14)),
                                            alignment: Alignment.center,
                                            child: Text(cat['icon'] ?? '', style: const TextStyle(fontSize: 24)),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(cat['name_ar'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                if (cat['description'] != null) ...[
                                                  const SizedBox(height: 3),
                                                  Text(cat['description'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_left, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                )),

                            const SizedBox(height: 14),
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

                            const SizedBox(height: 30),
                            const Divider(),
                            const SizedBox(height: 14),
                            const Text('عن بلدنا فلسطين',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                            const SizedBox(height: 8),
                            const Text(
                              'منصة فلسطينية شاملة تهدف لجمع المحلات والعقارات والسيارات والوظائف والخدمات والإعلانات في مكان واحد، لتسهيل الوصول للخدمات والفرص داخل جميع محافظات فلسطين.',
                              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.7),
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
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
                  Text(item['description'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
