import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../../core/network/mqtt/providers/mqtt_providers.dart';
import '../model/asset_summary_model.dart';
import 'dashboard_tank_visual.dart';

/// Parses the `cM` field from the MQTT payload into a key→value map.
/// Example cM: "10081 TNP:100: TNL:50659: PTN:0.0: GAS:1 : KL:97644 : TON:111.420 : CUM: 85640 : BAT:0.00 : SOL:0.00 : CSQ: 48: DT:01/01/1970: TIM:00;20;08"
Map<String, String> _parseCm(String cm) {
  final result = <String, String>{};
  // Match KEY:VALUE pairs where value may contain digits, dots, semicolons, slashes
  final re = RegExp(r'([A-Z]+)\s*:\s*([^:A-Z]+)');
  for (final m in re.allMatches(cm)) {
    final key = m.group(1)!.trim();
    final val = m.group(2)!.trim().replaceAll(RegExp(r'[\s:]+$'), '');
    result[key] = val;
  }
  return result;
}

class DetailedAssetCard extends ConsumerStatefulWidget {
  final AssetSummaryGroup group;

  const DetailedAssetCard({super.key, required this.group});

  @override
  ConsumerState<DetailedAssetCard> createState() => _DetailedAssetCardState();
}

class _DetailedAssetCardState extends ConsumerState<DetailedAssetCard> {
  // Live values parsed from MQTT
  String _gas = '--';
  String _pressure = '--';
  String _level = '--';
  String _kl = '--';
  String _cubicMeter = '--';
  String _ton = '--';
  String _batteryVolt = '--';
  String _solarVolt = '--';
  double _levelPerc = 0.0;
  bool _hasReceivedData = false;

  late String _mqttTopic;
  StreamSubscription<AsyncValue<MqttMessageModel>>? _streamSub;

  @override
  void initState() {
    super.initState();
    // Build topic: tweet/<deviceId>
    _mqttTopic = 'tweet/${widget.group.deviceId}';

    // Seed Gas from static reading
    final readingsMap = {for (var r in widget.group.readings) r.item.toLowerCase(): r};
    _gas = readingsMap['gas']?.readingValue ?? '--';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initMqtt();
    });
  }

  @override
  void didUpdateWidget(DetailedAssetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.deviceId != widget.group.deviceId) {
      // Topic changed! Unsubscribe old, reset state, and subscribe new
      _unsubscribeFromTopic('tweet/${oldWidget.group.deviceId}');
      
      setState(() {
        _mqttTopic = 'tweet/${widget.group.deviceId}';
        _hasReceivedData = false;
        _gas = '--';
        _pressure = '--';
        _level = '--';
        _kl = '--';
        _cubicMeter = '--';
        _ton = '--';
        _batteryVolt = '--';
        _solarVolt = '--';
        _levelPerc = 0.0;
      });

      _initMqtt();
    }
  }

  void _unsubscribeFromTopic(String topic) {
    try {
      ref.read(mqttProvider.notifier).unsubscribeFromTopic(topic);
    } catch (_) {}
  }

  void _initMqtt() {
    // Ensure MQTT is connected
    final mqttNotifier = ref.read(mqttProvider.notifier);
    mqttNotifier.initializeAndConnect().then((_) {
      if (mounted) {
        mqttNotifier.subscribeToTopic(_mqttTopic, onMessage: _onMessage);
      }
    });
  }

  void _onMessage(MqttMessageModel message) {
    if (!mounted) return;

    final data = message.data;
    final cm = (data['cM'] as String? ?? '').trim();
    
    // Skip status-only messages that don't contain sensor data
    if (cm.contains('DATA DELAY')) return;

    final parsed = _parseCm(cm);

    // Extract GAS type from cM field (GAS:1 means Oxygen typically, or use product name)
    final gasCode = parsed['GAS'] ?? '';

    // Level: TNP (percentage 0-100)
    final tnpStr = parsed['TNP'] ?? '0';
    final tnp = double.tryParse(tnpStr) ?? 0.0;

    // KL: raw liters → KL (divide by 1000) or direct if already KL
    final klStr = parsed['KL'] ?? '0';
    final klVal = double.tryParse(klStr) ?? 0.0;

    // TON
    final tonStr = parsed['TON'] ?? '0';

    // CUM = Cubic Meter (m³)
    final cumStr = parsed['CUM'] ?? '0';
    final cumVal = double.tryParse(cumStr) ?? 0.0;

    // PTN = Pressure
    final ptnStr = parsed['PTN'] ?? '0';

    // BAT = Battery Volt
    final batStr = parsed['BAT'] ?? '0';

    // SOL = Solar Volt
    final solStr = parsed['SOL'] ?? '0';

    setState(() {
      _hasReceivedData = true;

      // Gas: keep product name if GAS code not descriptive
      if (gasCode.isNotEmpty) {
        _gas = _gasCodeToName(gasCode, widget.group.readings
            .where((r) => r.item.toLowerCase() == 'gas')
            .firstOrNull
            ?.readingValue ?? 'Oxygen');
      }

      _pressure = ptnStr;
      _levelPerc = (tnp / 100.0).clamp(0.0, 1.0);
      _level = '${tnp.toStringAsFixed(2)} %';

      // KL: raw value from device is in liters → always divide by 1000 to get KL
      _kl = (klVal / 1000.0).toStringAsFixed(3);

      // Cubic Meter: CUM value direct (m³)
      _cubicMeter = cumVal.toStringAsFixed(2);

      _ton = tonStr;
      _batteryVolt = batStr;
      _solarVolt = solStr;
    });
  }

  String _gasCodeToName(String code, String fallback) {
    switch (code.trim()) {
      case '1': return 'Oxygen';
      case '2': return 'Nitrogen';
      case '3': return 'CO2';
      case '4': return 'Argon';
      default: return fallback;
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    // Unsubscribe from topic on dispose
    try {
      ref.read(mqttProvider.notifier).unsubscribeFromTopic(_mqttTopic);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch connection state to update banner
    final connectionState = ref.watch(mqttProvider);
    final isConnected = connectionState.isConnected;

    // Also listen for stream updates via the stream provider
    ref.listen(mqttTopicStreamProvider(_mqttTopic), (_, next) {
      next.whenData(_onMessage);
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Header Bar
          _buildTopBar(),

          // MQTT Status Banner
          _buildStatusBanner(isConnected),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Tank Visual
                Expanded(
                  flex: 3,
                  child: Center(
                    child: DashboardTankVisual(levelPercentage: _levelPerc),
                  ),
                ),

                const SizedBox(width: 24),

                // Right: Data Grid
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      _buildDataRow([
                        _buildDataSlot('Gas', _gas),
                        _buildDataSlot('Pressure', _pressure),
                      ]),
                      const SizedBox(height: 16),
                      _buildDataRow([
                        _buildDataSlot('Level', _level),
                        _buildDataSlot('KL', _kl),
                      ]),
                      const SizedBox(height: 16),
                      _buildDataRow([
                        _buildDataSlot('Cubic Meter', _cubicMeter),
                        _buildDataSlot('Ton', _ton),
                      ]),
                      const SizedBox(height: 16),
                      _buildDataRow([
                        _buildDataSlot('Battery Volt', _batteryVolt),
                        _buildDataSlot('Solar Volt', _solarVolt),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.navigation, color: Colors.white, size: 20),
          Column(
            children: [
              Text(
                (widget.group.deviceName != null && widget.group.deviceName!.isNotEmpty)
                    ? widget.group.deviceName!
                    : widget.group.deviceId,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  children: [
                    TextSpan(
                      text: widget.group.plantName.isEmpty
                          ? 'Unknown Site'
                          : widget.group.plantName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (widget.group.companyName != null &&
                        widget.group.companyName!.isNotEmpty) ...[
                      TextSpan(
                        text: ' [${widget.group.companyName}]',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ] else ...[
                      TextSpan(
                        text: ' [No Company]',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Icon(Icons.info_outline, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isConnected) {
    final Color bgColor;
    final Color textColor;
    final String message;

    if (!isConnected) {
      bgColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
      message = 'App cannot communicate with MQTT';
    } else if (!_hasReceivedData) {
      bgColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange.shade700;
      message = 'MQTT Connected — waiting for data on $_mqttTopic...';
    } else {
      bgColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green.shade700;
      message = 'Live data — topic: $_mqttTopic';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConnected
                ? (_hasReceivedData ? Icons.wifi : Icons.wifi_tethering)
                : Icons.wifi_off,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            message,
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(List<Widget> children) {
    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 16),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _buildDataSlot(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF141E7A), width: 1),
      ),
      child: Column(
        children: [
          // Slot Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF141E7A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Slot Body
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
