import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

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
  bool _loadingExtras = true;

  @override
  void initState() {
    super.initState();
    _loadExtras();
    final views = (widget.listing['views_count'] as int?) ?? 0;
    _service.incrementViews(widget.listing['id'], views);
  }

  Future<void> _loadExtras() async {
    try {
      final images = await _service.getListingImages(widget.listing['id']);
      final hours = await _service.getListingHours(widget.listing['id']);
      if (mounted) {
        setState(() {
          _images = images;
          _hours = hours;
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

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final phone = listing['phone'] as String?;
    final whatsapp = (listing['whatsapp'] as String?) ?? phone;
    final views = (listing['views_count'] as int?) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.sandLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: AppColors.oliveDeep,
            flexibleSpace: FlexibleSpaceBar(
              background: _images.isNotEmpty
                  ? PageView(
                      children: _images
                          .map((img) => Image.network(img['image_url'], fit: BoxFit.cover))
                          .toList(),
                    )
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
                        child: Text(
                          listing['title'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
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
                  if (listing['is_verified'] == true)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('✓ موثّق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _call(phone),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ok,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.call, size: 18),
                          label: const Text('اتصال'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _whatsapp(whatsapp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
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
                      final open = h['open_time'];
                      final close = h['close_time'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(day, style: const TextStyle(fontSize: 13)),
                            Text(
                              closed ? 'مغلق' : '${open ?? ''} - ${close ?? ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
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
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
