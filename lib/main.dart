import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/auth/recovery_deep_link.dart';
import 'core/onboarding/onboarding_state.dart';
import 'core/supabase/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  await loadOnboardingSeen();

  // Detect a password-reset deep link that cold-started the app, before the
  // first frame, so the router can route straight to the reset screen.
  await RecoveryLinkObserver.instance.start();

  runApp(
    const ProviderScope(
      child: LablioApp(),
    ),
  );
}
