import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class EditListingScreen extends StatefulWidget {
  final Map<String, dynamic> listing;
  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _service = SupabaseService();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _priceCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.listing['title'] ?? '');
    _descCtrl = TextEditingController(text: widget.listing['description'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.listing['phone'] ?? '');
    final customFields = widget.listing['custom_fields'];
    _priceCtrl = TextEditingController(
      text: (customFields is Map && customFields['price'] != null) ? customFields['price'].toString() : '',
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اسم النشاط مطلوب')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _service.updateListing(widget.listing['id'], {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'whatsapp': _phoneCtrl.text.trim(),
        if (_priceCtrl.text.trim().isNotEmpty) 'custom_fields': {'price': _priceCtrl.text.trim()},
        // إعادة النشاط لمراجعة الإدارة بعد أي تعديل
        'status': 'pending',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحفظ، وسيُعاد فحص النشاط قبل نشره من جديد')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sandLight,
      appBar: AppBar(title: const Text('تعديل النشاط')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('اسم النشاط', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
          const SizedBox(height: 6),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 18),
          const Text('رقم الهاتف / واتساب', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 18),
          const Text('السعر (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
          const SizedBox(height: 6),
          TextField(controller: _priceCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 18),
          const Text('وصف مختصر', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.oliveDeep)),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.clay,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('حفظ التعديلات'),
            ),
          ),
        ],
      ),
    );
  }
}
