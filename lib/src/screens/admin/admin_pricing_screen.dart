import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../models/pricing_model.dart';

final pricingStreamProvider = StreamProvider<List<PricingModel>>((ref) {
  return ref.read(firestoreServiceProvider).getAllPricingStream();
});

class AdminPricingScreen extends ConsumerWidget {
  const AdminPricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricingStream = ref.watch(pricingStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Admin theme usually dark
      appBar: AppBar(
        title: Text('Pricing Management', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: pricingStream.when(
        data: (pricingList) {
          // Ensure default exists in list visually if not fetched? 
          // Actually, if it's not in DB, we should probably allow creating it or it shows up as empty.
          // Let's sort: Default first, then alphabetical.
          
          final sortedList = List<PricingModel>.from(pricingList);
          sortedList.sort((a, b) {
            if (a.id == 'default') return -1;
            if (b.id == 'default') return 1;
            return a.city.compareTo(b.city);
          });

          if (sortedList.isEmpty) {
             // In case DB is empty, suggest creating default
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text('No Pricing Found', style: TextStyle(color: Colors.white)),
                   const SizedBox(height: 20),
                   ElevatedButton(
                     onPressed: () => _showEditDialog(context, ref, PricingModel.defaultPricing()),
                     child: const Text('Create Default Pricing'),
                   )
                 ],
               ),
             );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedList.length,
            itemBuilder: (context, index) {
              final pricing = sortedList[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(pricing.city, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'A4: ₹${pricing.a4BasePrice} | EdSheet: ₹${pricing.edSheetPrice}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFFFFAF00)),
                        onPressed: () => _showEditDialog(context, ref, pricing),
                      ),
                      if (pricing.id != 'default')
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePricing(context, ref, pricing.id),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFAF00),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showEditDialog(context, ref, null),
      ),
    );
  }

  void _deletePricing(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pricing?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(firestoreServiceProvider).deletePricing(id);
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, PricingModel? existing) {
    showDialog(
      context: context,
      builder: (context) => _PricingEditDialog(existing: existing),
    );
  }
}

class _PricingEditDialog extends ConsumerStatefulWidget {
  final PricingModel? existing;
  const _PricingEditDialog({this.existing});

  @override
  ConsumerState<_PricingEditDialog> createState() => _PricingEditDialogState();
}

class _PricingEditDialogState extends ConsumerState<_PricingEditDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _cityController;
  late TextEditingController _a4Controller;
  late TextEditingController _edSheetController;
  late TextEditingController _surcharge3Controller;
  late TextEditingController _surcharge2Controller;
  late TextEditingController _surcharge1Controller;

  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _isDefault = p?.id == 'default';

    _cityController = TextEditingController(text: p?.city ?? '');
    _a4Controller = TextEditingController(text: p?.a4BasePrice.toString() ?? '4.0');
    _edSheetController = TextEditingController(text: p?.edSheetPrice.toString() ?? '230.0');
    _surcharge3Controller = TextEditingController(text: p?.surcharge3Days.toString() ?? '1.0');
    _surcharge2Controller = TextEditingController(text: p?.surcharge2Days.toString() ?? '2.0');
    _surcharge1Controller = TextEditingController(text: p?.surcharge1Day.toString() ?? '3.0');
  }
  
  @override
  void dispose() {
    _cityController.dispose();
    _a4Controller.dispose();
    _edSheetController.dispose();
    _surcharge3Controller.dispose();
    _surcharge2Controller.dispose();
    _surcharge1Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Pricing' : 'Edit Pricing'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isDefault)
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  enabled: widget.existing == null, // Lock city name on edit to prevent ID mismatch usually, or allow but reconstruct ID
                ),
              const SizedBox(height: 10),
              Row(
                 children: [
                   Expanded(
                     child: TextFormField(
                       controller: _a4Controller,
                       decoration: const InputDecoration(labelText: 'A4 Base Price (₹)'),
                       keyboardType: TextInputType.number,
                       validator: (v) => v!.isEmpty ? 'Required' : null,
                     ),
                   ),
                   const SizedBox(width: 10),
                   Expanded(
                     child: TextFormField(
                       controller: _edSheetController,
                       decoration: const InputDecoration(labelText: 'EdSheet Price (₹)'),
                       keyboardType: TextInputType.number,
                       validator: (v) => v!.isEmpty ? 'Required' : null,
                     ),
                   ),
                 ],
              ),
              const SizedBox(height: 10),
              const Text('Surcharges (Added to A4 Base)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _surcharge3Controller,
                      decoration: const InputDecoration(labelText: '3 Days Left'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextFormField(
                      controller: _surcharge2Controller,
                      decoration: const InputDecoration(labelText: '2 Days Left'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                     child: TextFormField(
                       controller: _surcharge1Controller,
                       decoration: const InputDecoration(labelText: '1 Day Left'),
                       keyboardType: TextInputType.number,
                     ),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFAF00), foregroundColor: Colors.black),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final cityRaw = _cityController.text.trim();
      final id = widget.existing?.id ?? (_isDefault ? 'default' : cityRaw.toLowerCase().replaceAll(' ', '_')); 
      // Note: If creating new default manually, ensure ID is default.
      // If user typed 'Default' as city for new, handle gracefully.
      
      final newCity = _isDefault ? 'Default' : cityRaw;
      final finalId = _isDefault ? 'default' : id;

      final pricing = PricingModel(
        id: finalId,
        city: newCity,
        a4BasePrice: double.parse(_a4Controller.text),
        edSheetPrice: double.parse(_edSheetController.text),
        surcharge3Days: double.parse(_surcharge3Controller.text),
        surcharge2Days: double.parse(_surcharge2Controller.text),
        surcharge1Day: double.parse(_surcharge1Controller.text),
      );

      try {
        await ref.read(firestoreServiceProvider).setPricing(pricing);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint('Error saving pricing: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }
}
