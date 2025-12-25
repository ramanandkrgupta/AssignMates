import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/request_model.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController(); // TODO: Dropdown
  final _budgetController = TextEditingController();
  DateTime? _deadline;

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_deadline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a deadline')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = ref.read(authStateProvider).value;
        if (user == null) throw Exception('User not logged in');

        final firestoreService = ref.read(firestoreServiceProvider);
        
        // Generate a simple ID or let Firestore do it (we'll fix later)
        // For now, let's assume we can create a doc ref.
        // Actually, let's add a createRequest method to FirestoreService first.
        
        final newRequest = RequestModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
          studentId: user.uid,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          subject: _subjectController.text.trim(),
          deadline: _deadline!,
          budget: double.tryParse(_budgetController.text.trim()) ?? 0.0,
          createdAt: DateTime.now(),
        );

        
        await firestoreService.createRequest(newRequest);
        
        // Mock success for UI dev
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request Created Successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Physics Lab Report',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                items: ['Physics', 'Chemistry', 'Math', 'Computer Science', 'English', 'Other']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  _subjectController.text = value ?? '';
                },
                validator: (value) => value == null || value.isEmpty ? 'Please select a subject' : null,
              ),
              const SizedBox(height: 16),
               TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Describe your assignment details...',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Deadline',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _deadline == null
                              ? 'Select Date'
                              : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Budget (₹)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                         if (value == null || value.isEmpty) return 'Enter budget';
                         if (double.tryParse(value) == null) return 'Invalid number';
                         return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // File Picker (Placeholder)
              OutlinedButton.icon(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File Upload coming soon!')));
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Attach File (Optional)'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Request', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
