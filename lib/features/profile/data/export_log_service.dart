import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records an audit row in `pdf_export_logs` each time a doctor PDF is
/// exported: the user, the timestamp, how many biomarkers were included,
/// and basic device information.
class ExportLogService {
  final SupabaseClient _client;
  ExportLogService(this._client);

  /// Inserts one export-log row. Best-effort: a failure here must never block
  /// the actual share, so callers should treat thrown errors as non-fatal.
  Future<void> logPdfExport({
    required int biomarkerCount,
    required bool includedMedical,
    String exportType = 'doctor_pdf',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final device = await _deviceInfo();

    await _client.from('pdf_export_logs').insert({
      'user_id': userId,
      // exported_at defaults to now() server-side; sent explicitly for clarity.
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'export_type': exportType,
      'biomarker_count': biomarkerCount,
      'included_medical': includedMedical,
      'platform': device.platform,
      'device_model': device.model,
      'os_version': device.osVersion,
      'app_version': device.appVersion,
    });
  }

  Future<_DeviceInfo> _deviceInfo() async {
    String? appVersion;
    try {
      final pkg = await PackageInfo.fromPlatform();
      appVersion = '${pkg.version}+${pkg.buildNumber}';
    } catch (_) {/* leave null */}

    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        return _DeviceInfo(
          platform: 'android',
          model: '${a.manufacturer} ${a.model}'.trim(),
          osVersion: 'Android ${a.version.release} (SDK ${a.version.sdkInt})',
          appVersion: appVersion,
        );
      }
      if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        return _DeviceInfo(
          platform: 'ios',
          model: i.utsname.machine,
          osVersion: '${i.systemName} ${i.systemVersion}',
          appVersion: appVersion,
        );
      }
    } catch (_) {/* fall through to generic */}

    return _DeviceInfo(
      platform: Platform.operatingSystem,
      model: null,
      osVersion: Platform.operatingSystemVersion,
      appVersion: appVersion,
    );
  }
}

class _DeviceInfo {
  final String? platform;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  const _DeviceInfo({
    this.platform,
    this.model,
    this.osVersion,
    this.appVersion,
  });
}
