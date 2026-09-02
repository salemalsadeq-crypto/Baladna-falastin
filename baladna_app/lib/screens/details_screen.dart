import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class DetailsScreen extends StatelessWidget {
  final Map<String, dynamic> listing;
  const DetailsScreen({super.key, required this.listing});

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _whatsapp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final phone = listing['phone'] as String?;
    final whatsapp = (listing['whatsapp'] as String?) ?? phone;

    return Scaffold(
      backgroundColor: AppColors.sandLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: AppColors.oliveDeep,
            flexibleSpace: const FlexibleSpaceBar(
              background: DecoratedBox(
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
                  Text(
                    listing['title'] ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  const Divider(height: 36),
                  if (listing['address_text'] != null) ...[
                    const Text('الموقع', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(listing['address_text'], style: const TextStyle(fontSize: 14)),
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
