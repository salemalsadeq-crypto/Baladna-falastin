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
        const SnackBar(content: Text('عبي الاسم والقسم والمحافظة على الاقل')),
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
          const SnackBar(content: Text('تم الارسال بنجاح راح نراجعه ونفعله قريبا')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('صار خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اضف نشاطك')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text('اسم النشاط', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'مثال مطعم ابو ياسين'),
                ),
                const SizedBox(height: 18),

                const Text('القسم', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
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

                const Text('المحافظة', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
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

                const Text('رقم الهاتف او الواتساب', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '05XXXXXXXX'),
                ),
                const SizedBox(height: 18),

                const Text('وصف مختصر', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'اكتب وصفا بسيطا'),
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
                        : const Text('ارسال للمراجعة', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }
}
