import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One [ScrollController] per bottom-nav tab. Each tab screen attaches its
/// controller to its main scroll view; tapping the already-active tab scrolls
/// that tab back to the top (a standard bottom-nav expectation).
final navScrollControllersProvider = Provider<List<ScrollController>>((ref) {
  final controllers = List.generate(5, (_) => ScrollController());
  ref.onDispose(() {
    for (final c in controllers) {
      c.dispose();
    }
  });
  return controllers;
});

/// Scroll a tab's content to the top, if its controller is attached.
void scrollTabToTop(WidgetRef ref, int index) {
  final c = ref.read(navScrollControllersProvider)[index];
  if (c.hasClients) {
    c.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }
}
