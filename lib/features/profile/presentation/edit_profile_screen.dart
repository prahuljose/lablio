import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../data/profile_model.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_form_fields.dart';

const _maxAvatarBytes = 2 * 1024 * 1024; // 2 MB

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  DateTime? _dob;
  String? _sex;
  String? _bloodType;

  bool _initialised = false;
  bool _saving = false;
  bool _uploadingAvatar = false;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _hydrate(ProfileModel? p) {
    if (_initialised || p == null) return;
    _initialised = true;
    _dob = p.dateOfBirth;
    _sex = p.sex;
    _bloodType = p.bloodType;
    _heightController.text = p.heightCm?.toStringAsFixed(0) ?? '';
    _weightController.text = p.weightKg?.toStringAsFixed(1).replaceAll('.0', '') ?? '';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final size = await file.length();
    if (size > _maxAvatarBytes) {
      if (mounted) {
        _snack('Image is too large. Please pick one under 2 MB.',
            isError: true);
      }
      return;
    }

    setState(() => _uploadingAvatar = true);
    try {
      await ref.read(profileProvider.notifier).uploadAvatar(file);
      if (mounted) _snack('Profile picture updated');
    } catch (e) {
      if (mounted) _snack('Could not upload picture: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    final current = ref.read(profileProvider).valueOrNull;
    if (current == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save(
            current.copyWith(
              dateOfBirth: _dob,
              sex: _sex,
              bloodType: _bloodType,
              heightCm: double.tryParse(_heightController.text.trim()),
              weightKg: double.tryParse(_weightController.text.trim()),
            ),
          );
      if (mounted) {
        _snack('Profile saved');
        context.pop();
      }
    } catch (e) {
      if (mounted) _snack('Could not save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.high : AppColors.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    _hydrate(profileAsync.valueOrNull);
    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;
    final name = profileAsync.valueOrNull?.fullName ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // ── Tappable avatar ───────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            _initials(name),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  if (_uploadingAvatar)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Tap to change photo',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textTertiary)),
          ),
          const SizedBox(height: 28),

          // ── Date of birth ─────────────────────────────────────────
          const _Label('Date of birth'),
          const SizedBox(height: 8),
          _PickerTile(
            icon: Icons.cake_outlined,
            text: _dob == null
                ? 'Select'
                : DateFormat('MMMM d, yyyy').format(_dob!),
            onTap: _pickDob,
          ),
          const SizedBox(height: 20),

          // ── Sex ───────────────────────────────────────────────────
          const _Label('Sex'),
          const SizedBox(height: 8),
          SexSelector(
            value: _sex,
            onChanged: (v) => setState(() => _sex = v),
          ),
          const SizedBox(height: 20),

          // ── Height + Weight ───────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Height'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _heightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        suffixText: 'cm',
                        prefixIcon: Icon(Icons.height),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Weight'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        suffixText: 'kg',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Blood type ────────────────────────────────────────────
          const _Label('Blood type'),
          const SizedBox(height: 10),
          BloodTypeSelector(
            value: _bloodType,
            onChanged: (v) => setState(() => _bloodType = v),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      );
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _PickerTile(
      {required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(text,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
