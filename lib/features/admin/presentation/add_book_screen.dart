import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/core.dart';
import '../../books/book_provider.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _stockController = TextEditingController();
  final _shelfLocationController = TextEditingController();
  final _pdfUrlController = TextEditingController();

  BookType _selectedType = BookType.physical;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _coverUrlController.dispose();
    _stockController.dispose();
    _shelfLocationController.dispose();
    _pdfUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newBook = Book(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      coverUrl: _coverUrlController.text.trim(),
      type: _selectedType,
      stock: _selectedType == BookType.physical
          ? int.tryParse(_stockController.text) ?? 0
          : 0,
      shelfLocation: _selectedType == BookType.physical
          ? _shelfLocationController.text.trim()
          : null,
      pdfUrl: _selectedType == BookType.ebook
          ? _pdfUrlController.text.trim()
          : null,
    );

    final success = await ref.read(bookListProvider.notifier).addBook(newBook);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add book'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        toolbarHeight: 56,
        title: const Text('Add New Book'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _buildLabel('Book Title'),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Enter book title'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Author
              _buildLabel('Author'),
              TextFormField(
                controller: _authorController,
                decoration: _inputDecoration('Enter author name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Author is required' : null,
              ),
              const SizedBox(height: 16),

              // Cover URL
              _buildLabel('Cover Image URL'),
              TextFormField(
                controller: _coverUrlController,
                decoration: _inputDecoration('Paste image URL'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Cover URL is required' : null,
              ),
              const SizedBox(height: 16),

              // Book Type Dropdown
              _buildLabel('Book Type'),
              DropdownButtonFormField<BookType>(
                value: _selectedType,
                decoration: _inputDecoration('Select type'),
                items: const [
                  DropdownMenuItem(
                    value: BookType.physical,
                    child: Text('Physical Book'),
                  ),
                  DropdownMenuItem(
                    value: BookType.ebook,
                    child: Text('E-Book'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Conditional Fields
              if (_selectedType == BookType.physical) ...[
                // Stock
                _buildLabel('Initial Stock'),
                TextFormField(
                  controller: _stockController,
                  decoration: _inputDecoration('Enter stock quantity'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Stock is required';
                    if (int.tryParse(v) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Shelf Location
                _buildLabel('Shelf Location'),
                TextFormField(
                  controller: _shelfLocationController,
                  decoration: _inputDecoration('e.g. A-01-3'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Location is required' : null,
                ),
              ] else ...[
                // PDF URL for Ebook
                _buildLabel('PDF URL'),
                TextFormField(
                  controller: _pdfUrlController,
                  decoration: _inputDecoration('Enter PDF URL or path'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'PDF URL is required' : null,
                ),
              ],
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.plus),
                  label: Text(_isLoading ? 'Adding...' : 'Add Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
