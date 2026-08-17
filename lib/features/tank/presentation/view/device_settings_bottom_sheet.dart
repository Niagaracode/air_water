// lib/features/tank/presentation/view/device_settings_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme/app_theme.dart';
import '../../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../../core/network/mqtt/providers/mqtt_providers.dart';

/// Shows the live device settings for [deviceId], pulled from the MQTT
/// broker, in a modal bottom sheet.

/// Any other payload on this topic (a different purpose) is ignored. Since
/// both kinds can arrive independently, each is tracked and shown as its
/// own section rather than overwriting one another.
Future<void> showDeviceSettingsBottomSheet(
    BuildContext context, {
      required String deviceId,
    }) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true, // cover the whole app (sidebar included), not just the nested tab Navigator
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DeviceSettingsBottomSheet(deviceId: deviceId),
  );
}

class DeviceSettingsBottomSheet extends ConsumerStatefulWidget {
  final String deviceId;

  const DeviceSettingsBottomSheet({super.key, required this.deviceId});

  @override
  ConsumerState<DeviceSettingsBottomSheet> createState() =>
      _DeviceSettingsBottomSheetState();
}

class _DeviceSettingsBottomSheetState
    extends ConsumerState<DeviceSettingsBottomSheet> {
  late final String _requestTopic;
  late final String _responseTopic;

  Map<String, String>? _calibrationSettings;
  Map<String, String>? _channelSettings;
  String? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _requestTopic = 'apptolevel/${widget.deviceId}';
    _responseTopic = 'level/${widget.deviceId}';

    // Ask the device to publish its current settings as soon as the sheet
    // opens. Runs after first frame so the stream provider below is already
    // subscribed and won't miss the response.
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestSettings());
  }

  void _requestSettings() {
    ref.read(mqttProvider.notifier).publishMessage(_requestTopic, {
      'sentSms': 'vgassetting',
    });
  }

  /// Parses the SMS-style `cM` string into a key/value map.
  /// e.g. "CALMF:100000,OFSET:0,CALKL:1971" ->
  ///      {"CALMF": "100000", "OFSET": "0", "CALKL": "1971"}
  /// Malformed trailing fragments with no colon (truncated data) are
  /// skipped rather than throwing.
  Map<String, String> _parseCmField(String cm) {
    final result = <String, String>{};
    for (final part in cm.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final colonIndex = trimmed.indexOf(':');
      if (colonIndex == -1) continue;
      final key = trimmed.substring(0, colonIndex).trim();
      final value = trimmed.substring(colonIndex + 1).trim();
      if (key.isEmpty) continue;
      result[key] = value;
    }
    return result;
  }

  void _handleMessage(MqttMessageModel message) {
    final cm = message.data['cM'];
    if (cm is! String) return;

    final parsed = _parseCmField(cm);
    if (parsed.isEmpty) return;

    final date = message.data['cD']?.toString();
    final time = message.data['cT']?.toString();

    if (parsed.containsKey('CALMF')) {
      setState(() {
        _calibrationSettings = parsed;
        if (date != null && time != null) _lastUpdated = '$date  $time';
      });
    } else if (parsed.containsKey('CH')) {
      setState(() {
        _channelSettings = parsed;
        if (date != null && time != null) _lastUpdated = '$date  $time';
      });
    }
    // Any other payload kind on this topic is ignored on purpose.
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(mqttTopicStreamProvider(_responseTopic));
    final isConnected = ref.watch(
      mqttProvider.select((s) => s.isConnected),
    );

    // React to every new message on the topic (not just the latest), so we
    // can accumulate both calibration and channel settings independently.
    ref.listen<AsyncValue<MqttMessageModel>>(
      mqttTopicStreamProvider(_responseTopic),
          (previous, next) => next.whenData(_handleMessage),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              _buildHeader(isConnected),
              if (_lastUpdated != null) _buildLastUpdated(),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Expanded(
                child: _buildBody(scrollController, settingsAsync),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(bool isConnected) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          Icon(Icons.settings, size: 20, color: primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Device Settings',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.grey,
            ),
          ),
          Text(
            isConnected ? 'Live' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isConnected ? Colors.green.shade700 : Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, size: 20),
            color: primary,
            onPressed: _requestSettings,
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey.shade600,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Last updated: $_lastUpdated',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  // ==================== BODY ====================
  Widget _buildBody(
      ScrollController scrollController,
      AsyncValue<MqttMessageModel> settingsAsync,
      ) {
    // Show a hard error only if the stream itself errored AND we have no
    // data at all yet to fall back on.
    if (settingsAsync.hasError &&
        _calibrationSettings == null &&
        _channelSettings == null) {
      return _buildError(settingsAsync.error.toString());
    }

    if (_calibrationSettings == null && _channelSettings == null) {
      return _buildLoading();
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (_calibrationSettings != null)
          _buildSection(
            title: 'Calibration Settings',
            icon: Icons.tune,
            data: _calibrationSettings!,
          ),
        if (_calibrationSettings != null && _channelSettings != null)
          const SizedBox(height: 20),
        if (_channelSettings != null)
          _buildSection(
            title: 'Channel Settings',
            icon: Icons.settings_input_component,
            data: _channelSettings!,
          ),
        if (_calibrationSettings == null) _buildPendingSection('Calibration Settings'),
        if (_channelSettings == null) _buildPendingSection('Channel Settings'),
      ],
    );
  }

  Widget _buildPendingSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Waiting for $title…',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ==================== LOADING ====================
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Waiting for device response…',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Make sure the device is online',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ==================== ERROR ====================
  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 32),
            const SizedBox(height: 12),
            Text(
              'Could not load settings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _requestSettings,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SETTINGS SECTION ====================
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Map<String, String> data,
  }) {
    final entries = data.entries.toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...entries.map(
                (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _formatKey(entry.key),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      entry.value.isEmpty ? '—' : entry.value,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FORMATTING HELPERS ====================

  /// Turns `CALMF` / `DATA DELAY` / `T1Press` into "Calmf" / "Data Delay" /
  /// "T1 Press" for a cleaner label.
  String _formatKey(String key) {
    final spaced = key
        .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m.group(1)} ${m.group(2)}',
    )
        .replaceAll('_', ' ');
    return spaced
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}