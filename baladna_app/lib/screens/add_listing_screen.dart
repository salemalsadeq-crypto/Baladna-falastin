import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _service = SupabaseService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _regions = [];
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedRegion;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final cats = await _service.getCategories();
    final regs = await _service.getGovernorates();
    setState(() {
      _categories = cats;
      _regions = regs;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _selectedCategory == null || _selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in the name, category and governorate at least')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _service.addListing(
        title: _titleCtrl.text.trim(),
        categoryId: _selectedCategory!['id'],
        regionId: _selectedRegion!['id'],
        description: _descCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted successfully, we will review it soon')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add your listing')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text('Listing name', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Abu Yassin Restaurant'),
                ),
                const SizedBox(height: 18),

                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text('${c['icon'] ?? ''} ${c['name_ar']}')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 18),

                const Text('Governorate', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: _selectedRegion,
                  items: _regions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r['name_ar'])))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRegion = v),
                ),
                const SizedBox(height: 18),

                const Text('Phone / WhatsApp number', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '05XXXXXXXX'),
                ),
                const SizedBox(height: 18),

                const Text('Short description', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Write a short description...'),
                ),
                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.clay,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit for review', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }
}
