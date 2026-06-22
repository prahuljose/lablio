import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

const kBloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// Three-way segmented sex selector with icons.
class SexSelector extends StatelessWidget {
  final String? value; // 'male' | 'female' | 'other'
  final ValueChanged<String> onChanged;
  const SexSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _option('male', 'Male', Icons.male),
        const SizedBox(width: 10),
        _option('female', 'Female', Icons.female),
        const SizedBox(width: 10),
        _option('other', 'Other', Icons.transgender),
      ],
    );
  }

  Widget _option(String key, String label, IconData icon) {
    final selected = value == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.divider,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern blood-type picker — a wrap of rounded pills.
class BloodTypeSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  const BloodTypeSelector(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kBloodTypes.map((t) {
        final selected = value == t;
        return GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? Colors.transparent : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop,
                    size: 13,
                    color: selected ? Colors.white : AppColors.textTertiary),
                const SizedBox(width: 3),
                Text(
                  t,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
