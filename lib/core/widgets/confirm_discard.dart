import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';

/// Confirms abandoning unsaved edits. Returns true if the user chose to discard.
Future<bool> confirmDiscard(BuildContext context) async {
  final t = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.discardTitle),
      content: Text(t.discardBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(t.discardKeep),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(t.discardDiscard,
              style: const TextStyle(color: AppColors.high)),
        ),
      ],
    ),
  );
  return result ?? false;
}
