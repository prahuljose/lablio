import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/reports_provider.dart';

class AddReportScreen extends ConsumerStatefulWidget {
  const AddReportScreen({super.key});

  @override
  ConsumerState<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends ConsumerState<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _pdfFile;
  String? _pdfName;
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
        _pdfName = result.files.single.name;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(reportsProvider.notifier).add(
            title: _titleController.text.trim(),
            date: _selectedDate,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            pdfFile: _pdfFile,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.high),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Report'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Report title',
                hintText: 'e.g. Annual Blood Work',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Report date',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12)),
                        Text(
                          DateFormat('MMMM d, yyyy').format(_selectedDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this report...',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildPdfPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPicker() {
    return InkWell(
      onTap: _pickPdf,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pdfFile != null
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pdfFile != null ? AppColors.primary : AppColors.divider,
            style: _pdfFile != null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _pdfFile != null ? Icons.picture_as_pdf : Icons.upload_file,
              color: _pdfFile != null ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pdfFile != null ? 'PDF attached' : 'Attach PDF (optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _pdfFile != null
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                  ),
                  if (_pdfName != null)
                    Text(_pdfName!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                  else
                    Text('Tap to select a PDF lab report',
                        style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (_pdfFile != null)
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textTertiary),
                onPressed: () => setState(() {
                  _pdfFile = null;
                  _pdfName = null;
                }),
              ),
          ],
        ),
      ),
    );
  }
}
