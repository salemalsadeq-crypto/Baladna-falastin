import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'auth_screen.dart';

const _dayNames = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

class DetailsScreen extends StatefulWidget {
  final Map<String, dynamic> listing;
  const DetailsScreen({super.key, required this.listing});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _hours = [];
  List<Map<String, dynamic>> _ratings = [];
  bool _loadingExtras = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadExtras();
    _loadFavoriteStatus();
    final views = (widget.listing['views_count'] as int?) ?? 0;
    _service.incrementViews(widget.listing['id'], views);
  }

  Future<void> _loadFavoriteStatus() async {
    final fav = await _service.isFavorite(widget.listing['id']);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    if (_service.currentUser == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      if (_service.currentUser == null) return;
    }
    try {
      await _service.toggleFavorite(widget.listing['id'], _isFavorite);
      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadExtras() async {
    try {
      final images = await _service.getListingImages(widget.listing['id']);
      final hours = await _service.getListingHours(widget.listing['id']);
      final ratings = await _service.getRatings(widget.listing['id']);
      if (mounted) {
        setState(() {
          _images = images;
          _hours = hours;
          _ratings = ratings;
          _loadingExtras = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingExtras = false);
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _whatsapp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    await launchUrl(Uri.parse('https://wa.me/$clean'), mode: LaunchMode.externalApplication);
  }

  Future<void> _openMap() async {
    final lat = widget.listing['lat'];
    final lng = widget.listing['lng'];
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      final address = widget.listing['address_text'] ?? widget.listing['title'] ?? '';
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openRatingDialog() async {
    if (_service.currentUser == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      if (_service.currentUser == null) return;
    }
    int selected = 5;
    final commentCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('أضف تقييمك'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    return IconButton(
                      onPressed: () => setDialogState(() => selected = starIndex),
                      icon: Icon(
                        starIndex <= selected ? Icons.star : Icons.star_border,
                        color: AppColors.gold,
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'اكتب تعليقك (اختياري)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('إرسال')),
            ],
          );
        });
      },
    );
    if (result == true) {
      try {
        await _service.addOrUpdateRating(widget.listing['id'], selected, commentCtrl.text.trim());
        _loadExtras();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final phone = listing['phone'] as String?;
    final whatsapp = (listing['whatsapp'] as String?) ?? phone;
    final views = (listing['views_count'] as int?) ?? 0;
    final customFields = listing['custom_fields'];
    final price = (customFields is Map) ? customFields['price'] : null;

    final avgRating = _ratings.isEmpty
        ? 0.0
        : _ratings.map((r) => (r['rating'] as num).toDouble()).reduce((a, b) => a + b) / _ratings.length;

    return Scaffold(
      backgroundColor: AppColors.sandLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: AppColors.oliveDeep,
            actions: [
              IconButton(
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? AppColors.clay : Colors.white),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _images.isNotEmpty
                  ? PageView(children: _images.map((img) => Image.network(img['image_url'], fit: BoxFit.cover)).toList())
                  : const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.olive, AppColors.oliveDeep],
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(listing['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.visibility_outlined, size: 15, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text('$views', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (listing['is_verified'] == true)
                        Container(
                          margin: const EdgeInsets.only(top: 8, left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)),
                          child: const Text('✓ موثّق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      if (_ratings.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.sand)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 14, color: AppColors.gold),
                              const SizedBox(width: 3),
                              Text('${avgRating.toStringAsFixed(1)} (${_ratings.length})', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 10),
                    Text('$price', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.clay)),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _call(phone),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.ok, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                          icon: const Icon(Icons.call, size: 18),
                          label: const Text('اتصال'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _whatsapp(whatsapp),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('واتساب'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openMap,
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('افتح في الخرائط'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  const Divider(height: 36),
                  if (listing['address_text'] != null) ...[
                    const Text('الموقع', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(listing['address_text'], style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                  ],
                  if (!_loadingExtras && _hours.isNotEmpty) ...[
                    const Text('ساعات العمل', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    ..._hours.map((h) {
                      final day = _dayNames[h['day_of_week'] as int];
                      final closed = h['is_closed'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(day, style: const TextStyle(fontSize: 13)),
                            Text(closed ? 'مغلق' : '${h['open_time'] ?? ''} - ${h['close_time'] ?? ''}', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  if (listing['description'] != null) ...[
                    const Text('عن النشاط', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(listing['description'], style: const TextStyle(fontSize: 14, height: 1.6)),
                    const SizedBox(height: 20),
                  ],

                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('التقييمات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                      TextButton.icon(
                        onPressed: _openRatingDialog,
                        icon: const Icon(Icons.star_border, size: 18),
                        label: const Text('أضف تقييمك'),
                      ),
                    ],
                  ),
                  if (_ratings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('لا يوجد تقييمات بعد، كن أول من يقيّم', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._ratings.map((r) {
                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (i) => Icon(
                                    i < (r['rating'] as int) ? Icons.star : Icons.star_border,
                                    size: 16,
                                    color: AppColors.gold,
                                  )),
                            ),
                            if (r['comment'] != null && r['comment'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(r['comment'], style: const TextStyle(fontSize: 13)),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
