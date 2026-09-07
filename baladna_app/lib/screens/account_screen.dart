import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'favorites_screen.dart';
import 'my_listings_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _service = SupabaseService();

  @override
  Widget build(BuildContext context) {
    final user = _service.currentUser;
    return Scaffold(
      backgroundColor: AppColors.sandLight,
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('البريد الإلكتروني', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.storefront_outlined, color: AppColors.oliveDeep),
            title: const Text('أنشطتي'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()));
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.favorite_border, color: AppColors.clay),
            title: const Text('مفضلتي'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await _service.signOut();
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.clay,
                side: const BorderSide(color: AppColors.clay),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
