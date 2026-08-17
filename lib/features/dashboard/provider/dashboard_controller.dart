
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../core/network/mqtt/providers/mqtt_notifier.dart';
import '../../../core/network/mqtt/providers/mqtt_providers.dart';
import 'dashboard_provider.dart';

final dashboardControllerProvider = AsyncNotifierProvider<DashboardController, void>(
  DashboardController.new,
);

class DashboardController extends AsyncNotifier<void> {
  late final MqttNotifier _mqttNotifier;
  bool _initialized = false;

  // Keys that indicate an actual live sensor reading (not just a heartbeat/seq payload)
  static const Set<String> _liveDataKeys = {
    'level',
    'totalLevel',
    'pressure',
    'batteryV',
    'solarV',
    'signalStrength',
    'gas',
    'kl',
    'cumulative',
  };

  // Subscribe to ALL topics for debugging
  final String _mqttTopic = 'level/#';  // Change this after you identify the correct topic
  // final String _mqttTopic = 'level/#';  // Use this if you want to filter

  @override
  Future<void> build() async {
    if (_initialized) return;

    debugPrint('🏗️ Building DashboardController');
    _initialized = true;
    _mqttNotifier = ref.read(mqttProvider.notifier);

    // Initialize MQTT after build completes
    Future.microtask(() => _initializeMqtt());
  }

  // In dashboard_controller.dart _initializeMqtt() method
  Future<void> _initializeMqtt() async {
    try {
      debugPrint('🚀 Initializing MQTT from DashboardController');

      await _mqttNotifier.initializeAndConnect();

      await _mqttNotifier.subscribeToTopic(_mqttTopic,
        onMessage: _onMqttMessage,
      );

      debugPrint('✅ DashboardController MQTT initialization complete');
    } catch (e) {
      debugPrint('❌ DashboardController MQTT initialization error: $e');
    }
  }

  void _onMqttMessage(MqttMessageModel msg) {
    /* debugPrint('═══════════════════════════════════════════════');
    debugPrint('📩📩📩 MESSAGE RECEIVED IN DASHBOARD CONTROLLER 📩📩📩');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('📌 Topic: ${msg.rawPayload}');
    debugPrint('📦 Raw Data: ${msg.data}');
    debugPrint('🕐 Timestamp: ${msg.timestamp}');
    debugPrint('───────────────────────────────────────────────');*/

    try {
      // Parse MQTT data
      final parsed = _parseMqtt(msg.data);
      debugPrint('✅ Parsed data: $parsed');

      // Only update the dashboard if the payload actually contained live
      // sensor data (TNP/PTN/BAT/etc). Skip bare heartbeat/sequence-only
      // payloads like cM: "081" with no key:value data.
      final hasLiveData = _liveDataKeys.any((key) => parsed.containsKey(key));

      if (hasLiveData) {
        ref.read(tankDataProvider.notifier).updateFromMqtt(parsed);
        debugPrint('✅ Tank data updated successfully');
      } else {
        debugPrint('⏭️ Skipped update — no live data in payload (likely heartbeat/seq-only: "${msg.data['cM']}")');
      }
    } catch (e) {
      debugPrint('❌ Error processing MQTT message: $e');
    }

    debugPrint('═══════════════════════════════════════════════');
  }

  Map<String, dynamic> _parseMqtt(Map<String, dynamic> json) {

    final result = <String, dynamic>{};

    // Extract device ID - use safe access
    final deviceId = json['cC']?.toString();
    if (deviceId != null && deviceId.isNotEmpty) {
      result['deviceId'] = deviceId;
    }

    final cM = json['cM']?.toString() ?? '';
    debugPrint('📊 Raw cM: $cM');

    if (cM.isNotEmpty) {
      // Remove leading sequence number (e.g., "03081 ")
      String cleanCM = cM;
      final seqMatch = RegExp(r'^(\d+)\s+').firstMatch(cM);
      if (seqMatch != null) {
        final seqNum = seqMatch.group(1);
        if (seqNum != null) {
          result['sequenceNumber'] = int.tryParse(seqNum);
          cleanCM = cM.substring(seqMatch.end);
          debugPrint('📊 Sequence number: ${result['sequenceNumber']}');
        }
      }

      // Parse key:value pairs - handles both "KEY:value" and "KEY: value" formats
      final pattern = RegExp(r'(\w+):\s*([\d.]+)');
      final matches = pattern.allMatches(cleanCM);

      debugPrint('🔍 Found ${matches.length} matches in cM');

      for (var m in matches) {
        final key = m.group(1)?.trim();
        final value = m.group(2)?.trim();

        if (key != null && value != null) {
          final numValue = double.tryParse(value);
          debugPrint('📊 Extracted: $key = $value (as number: $numValue)');

          switch (key) {
            case 'TNP':
              if (numValue != null) {
                result['level'] = numValue;
                debugPrint('📊 Level: $numValue');
              }
              break;
            case 'TON':
              if (numValue != null) {
                //result['level'] = numValue;
                debugPrint('📊 TON: $numValue');
              }
              break;

            case 'TNL':
              if (numValue != null) {
                result['totalLevel'] = numValue;
                debugPrint('📊 Total Level: $numValue');
              }
              break;

            case 'PTN':
              if (numValue != null) {
                result['pressure'] = numValue;
                debugPrint('📊 Pressure: $numValue');
              }
              break;

            case 'BAT':
              if (numValue != null) {
                result['batteryV'] = numValue;
                debugPrint('🔋 Battery: $numValue');
              }
              break;

            case 'SOL':
              if (numValue != null) {
                result['solarV'] = numValue;
                debugPrint('☀️ Solar: $numValue');
              }
              break;

            case 'CSQ':
              if (numValue != null) {
                result['signalStrength'] = numValue;
                debugPrint('📶 Signal: $numValue');
              }
              break;

            case 'GAS':
              if (numValue != null) {
                result['gas'] = numValue;
                debugPrint('⛽ Gas: $numValue');
              }
              break;

            case 'KL':
              if (numValue != null) {
                result['kl'] = numValue;
                debugPrint('📊 KL: $numValue');
              }
              break;

            case 'CUM':
              if (numValue != null) {
                result['cumulative'] = numValue;
                debugPrint('📊 Cumulative: $numValue');
              }
              break;

            default:
              debugPrint('⚠️ Unknown key: $key = $value');
          }
        }
      }

      // Extract date from cM if not in main fields
      final dtMatch = RegExp(r'DT:\s*([\d/]+)').firstMatch(cleanCM);
      if (dtMatch != null) {
        final dateFromCM = dtMatch.group(1);
        if (dateFromCM != null) {
          result['dateFromCM'] = dateFromCM;
          debugPrint('📅 Date from CM: $dateFromCM');
        }
      }

      // Extract time from cM if not in main fields
      final timMatch = RegExp(r'TIM:\s*([\d;:]+)').firstMatch(cleanCM);
      if (timMatch != null) {
        final timeFromCM = timMatch.group(1);
        if (timeFromCM != null) {
          result['timeFromCM'] = timeFromCM;
          debugPrint('🕐 Time from CM: $timeFromCM');
        }
      }
    }

    // Parse date and time - priority: main fields > extracted from cM
    String date = json['cD']?.toString().trim() ?? '';
    String time = json['cT']?.toString().trim() ?? '';

    if (date.isEmpty && result.containsKey('dateFromCM')) {
      date = result['dateFromCM'].toString();
    }
    if (time.isEmpty && result.containsKey('timeFromCM')) {
      time = result['timeFromCM'].toString();
    }

    debugPrint('📅 Final Date: $date, Time: $time');

    if (date.isNotEmpty && time.isNotEmpty) {
      try {
        // Handle different time formats (both ; and :)
        String cleanTime = time.replaceAll(';', ':');
        debugPrint('🕐 Clean time: $cleanTime');

        final dateTime = DateFormat('dd/MM/yyyy HH:mm:ss')
            .parse('$date $cleanTime');
        result['lastUpdate'] = dateTime;
        debugPrint('✅ Parsed DateTime: $dateTime');
      } catch (e) {
        debugPrint('❌ Date parsing error: $e');
        result['lastUpdate'] = DateTime.now();
      }
    }

    // ✅ FIXED: Parse cL - use string literal, not variable
    if (json.containsKey('cL')) {
      final cL = json['cL']?.toString() ?? '';
      if (cL.isNotEmpty && cL != '\$L, NO DATA, ') {
        result['locationData'] = cL;
        debugPrint('📍 Location: $cL');
      }
    }

    // ✅ FIXED: Parse cZ - use string literal, not variable
    if (json.containsKey('cZ')) {
      final cZ = json['cZ']?.toString() ?? '';
      if (cZ.isNotEmpty) {
        result['zoneData'] = cZ;
        debugPrint('📍 Zone: $cZ');
      }
    }

    // ✅ FIXED: Parse mC - use string literal, not variable
    if (json.containsKey('mC')) {
      final mC = json['mC']?.toString() ?? '';
      if (mC.isNotEmpty) {
        result['messageType'] = mC;
        debugPrint('📨 Message Type: $mC');
      }
    }

    // Add raw data for debugging
    result['_raw'] = json;

    debugPrint('✅ Final parsed result: $result');
    return result;
  }

  // ==================== DEBUG METHODS ====================

  Future<void> testPublish() async {
    debugPrint('🧪 Testing publish...');
    try {
      await _mqttNotifier.publishMessage(
        'test/topic',
        {
          'test': 'hello',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('✅ Test publish successful');
    } catch (e) {
      debugPrint('❌ Test publish failed: $e');
    }
  }

  Future<void> testPublishToDevice(String deviceId) async {
    debugPrint('🧪 Publishing to device: $deviceId');
    try {
      await _mqttNotifier.publishMessage(
        'level/$deviceId',
        {
          'cC': deviceId,
          'cM': 'TNP:0.000 PTN:0.0 BAT:12.0 SOL:13.0',
          'cD': DateFormat('dd/MM/yyyy').format(DateTime.now()),
          'cT': DateFormat('HH:mm:ss').format(DateTime.now()),
        },
      );
      debugPrint('✅ Test publish to device successful');
    } catch (e) {
      debugPrint('❌ Test publish to device failed: $e');
    }
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _initialized,
      'topic': _mqttTopic,
      'subscriptions': _mqttNotifier.getSubscribedTopics(),
      'isConnected': ref.read(mqttProvider).isConnected,
      'hasCallbacks': _mqttNotifier.hasCallbacks(_mqttTopic),
      'callbackCount': _mqttNotifier.getCallbackCount(_mqttTopic),
      'lastMessages': _mqttNotifier.getAllMessages().keys,
    };
  }
}

/*

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../core/network/mqtt/providers/mqtt_notifier.dart';
import '../../../core/network/mqtt/providers/mqtt_providers.dart';
import 'dashboard_provider.dart';

final dashboardControllerProvider = AsyncNotifierProvider<DashboardController, void>(
  DashboardController.new,
);

class DashboardController extends AsyncNotifier<void> {
  late final MqttNotifier _mqttNotifier;
  bool _initialized = false;

  // Subscribe to ALL topics for debugging
  final String _mqttTopic = 'level/#';  // Change this after you identify the correct topic
  // final String _mqttTopic = 'level/#';  // Use this if you want to filter

  @override
  Future<void> build() async {
    if (_initialized) return;

    debugPrint('🏗️ Building DashboardController');
    _initialized = true;
    _mqttNotifier = ref.read(mqttProvider.notifier);

    // Initialize MQTT after build completes
    Future.microtask(() => _initializeMqtt());
  }

  // In dashboard_controller.dart _initializeMqtt() method
  Future<void> _initializeMqtt() async {
    try {
      debugPrint('🚀 Initializing MQTT from DashboardController');

      await _mqttNotifier.initializeAndConnect();

      await _mqttNotifier.subscribeToTopic(_mqttTopic,
        onMessage: _onMqttMessage,
      );

      debugPrint('✅ DashboardController MQTT initialization complete');
    } catch (e) {
      debugPrint('❌ DashboardController MQTT initialization error: $e');
    }
  }

  void _onMqttMessage(MqttMessageModel msg) {
   */
/* debugPrint('═══════════════════════════════════════════════');
    debugPrint('📩📩📩 MESSAGE RECEIVED IN DASHBOARD CONTROLLER 📩📩📩');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('📌 Topic: ${msg.rawPayload}');
    debugPrint('📦 Raw Data: ${msg.data}');
    debugPrint('🕐 Timestamp: ${msg.timestamp}');
    debugPrint('───────────────────────────────────────────────');*//*


    try {
      // Parse MQTT data
      final parsed = _parseMqtt(msg.data);
      debugPrint('✅ Parsed data: $parsed');

      // Update tank data
      ref.read(tankDataProvider.notifier).updateFromMqtt(parsed);
      debugPrint('✅ Tank data updated successfully');
    } catch (e) {
      debugPrint('❌ Error processing MQTT message: $e');
    }

    debugPrint('═══════════════════════════════════════════════');
  }

  Map<String, dynamic> _parseMqtt(Map<String, dynamic> json) {
   // debugPrint('🔍 Parsing MQTT JSON: $json');

    final result = <String, dynamic>{};

    // Extract device ID - use safe access
    final deviceId = json['cC']?.toString();
    if (deviceId != null && deviceId.isNotEmpty) {
      result['deviceId'] = deviceId;
    }

    // Parse compound message (cM)
    final cM = json['cM']?.toString() ?? '';
    debugPrint('📊 Raw cM: $cM');

    if (cM.isNotEmpty) {
      // Remove leading sequence number (e.g., "03081 ")
      String cleanCM = cM;
      final seqMatch = RegExp(r'^(\d+)\s+').firstMatch(cM);
      if (seqMatch != null) {
        final seqNum = seqMatch.group(1);
        if (seqNum != null) {
          result['sequenceNumber'] = int.tryParse(seqNum);
          cleanCM = cM.substring(seqMatch.end);
          debugPrint('📊 Sequence number: ${result['sequenceNumber']}');
        }
      }

      // Parse key:value pairs - handles both "KEY:value" and "KEY: value" formats
      final pattern = RegExp(r'(\w+):\s*([\d.]+)');
      final matches = pattern.allMatches(cleanCM);

      debugPrint('🔍 Found ${matches.length} matches in cM');

      for (var m in matches) {
        final key = m.group(1)?.trim();
        final value = m.group(2)?.trim();

        if (key != null && value != null) {
          final numValue = double.tryParse(value);
          debugPrint('📊 Extracted: $key = $value (as number: $numValue)');

          switch (key) {
            case 'TNP':
              if (numValue != null) {
                result['level'] = numValue;
                debugPrint('📊 Level: $numValue');
              }
              break;
            case 'TON':
              if (numValue != null) {
                //result['level'] = numValue;
                debugPrint('📊 TON: $numValue');
              }
              break;

            case 'TNL':
              if (numValue != null) {
                result['totalLevel'] = numValue;
                debugPrint('📊 Total Level: $numValue');
              }
              break;

            case 'PTN':
              if (numValue != null) {
                result['pressure'] = numValue;
                debugPrint('📊 Pressure: $numValue');
              }
              break;

            case 'BAT':
              if (numValue != null) {
                result['batteryV'] = numValue;
                debugPrint('🔋 Battery: $numValue');
              }
              break;

            case 'SOL':
              if (numValue != null) {
                result['solarV'] = numValue;
                debugPrint('☀️ Solar: $numValue');
              }
              break;

            case 'CSQ':
              if (numValue != null) {
                result['signalStrength'] = numValue;
                debugPrint('📶 Signal: $numValue');
              }
              break;

            case 'GAS':
              if (numValue != null) {
                result['gas'] = numValue;
                debugPrint('⛽ Gas: $numValue');
              }
              break;

            case 'KL':
              if (numValue != null) {
                result['kl'] = numValue;
                debugPrint('📊 KL: $numValue');
              }
              break;

            case 'CUM':
              if (numValue != null) {
                result['cumulative'] = numValue;
                debugPrint('📊 Cumulative: $numValue');
              }
              break;

            default:
              debugPrint('⚠️ Unknown key: $key = $value');
          }
        }
      }

      // Extract date from cM if not in main fields
      final dtMatch = RegExp(r'DT:\s*([\d/]+)').firstMatch(cleanCM);
      if (dtMatch != null) {
        final dateFromCM = dtMatch.group(1);
        if (dateFromCM != null) {
          result['dateFromCM'] = dateFromCM;
          debugPrint('📅 Date from CM: $dateFromCM');
        }
      }

      // Extract time from cM if not in main fields
      final timMatch = RegExp(r'TIM:\s*([\d;:]+)').firstMatch(cleanCM);
      if (timMatch != null) {
        final timeFromCM = timMatch.group(1);
        if (timeFromCM != null) {
          result['timeFromCM'] = timeFromCM;
          debugPrint('🕐 Time from CM: $timeFromCM');
        }
      }
    }

    // Parse date and time - priority: main fields > extracted from cM
    String date = json['cD']?.toString().trim() ?? '';
    String time = json['cT']?.toString().trim() ?? '';

    if (date.isEmpty && result.containsKey('dateFromCM')) {
      date = result['dateFromCM'].toString();
    }
    if (time.isEmpty && result.containsKey('timeFromCM')) {
      time = result['timeFromCM'].toString();
    }

    debugPrint('📅 Final Date: $date, Time: $time');

    if (date.isNotEmpty && time.isNotEmpty) {
      try {
        // Handle different time formats (both ; and :)
        String cleanTime = time.replaceAll(';', ':');
        debugPrint('🕐 Clean time: $cleanTime');

        final dateTime = DateFormat('dd/MM/yyyy HH:mm:ss')
            .parse('$date $cleanTime');
        result['lastUpdate'] = dateTime;
        debugPrint('✅ Parsed DateTime: $dateTime');
      } catch (e) {
        debugPrint('❌ Date parsing error: $e');
        result['lastUpdate'] = DateTime.now();
      }
    }

    // ✅ FIXED: Parse cL - use string literal, not variable
    if (json.containsKey('cL')) {
      final cL = json['cL']?.toString() ?? '';
      if (cL.isNotEmpty && cL != '\$L, NO DATA, ') {
        result['locationData'] = cL;
        debugPrint('📍 Location: $cL');
      }
    }

    // ✅ FIXED: Parse cZ - use string literal, not variable
    if (json.containsKey('cZ')) {
      final cZ = json['cZ']?.toString() ?? '';
      if (cZ.isNotEmpty) {
        result['zoneData'] = cZ;
        debugPrint('📍 Zone: $cZ');
      }
    }

    // ✅ FIXED: Parse mC - use string literal, not variable
    if (json.containsKey('mC')) {
      final mC = json['mC']?.toString() ?? '';
      if (mC.isNotEmpty) {
        result['messageType'] = mC;
        debugPrint('📨 Message Type: $mC');
      }
    }

    // Add raw data for debugging
    result['_raw'] = json;

    debugPrint('✅ Final parsed result: $result');
    return result;
  }

  // ==================== DEBUG METHODS ====================

  Future<void> testPublish() async {
    debugPrint('🧪 Testing publish...');
    try {
      await _mqttNotifier.publishMessage(
        'test/topic',
        {
          'test': 'hello',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('✅ Test publish successful');
    } catch (e) {
      debugPrint('❌ Test publish failed: $e');
    }
  }

  Future<void> testPublishToDevice(String deviceId) async {
    debugPrint('🧪 Publishing to device: $deviceId');
    try {
      await _mqttNotifier.publishMessage(
        'level/$deviceId',
        {
          'cC': deviceId,
          'cM': 'TNP:0.000 PTN:0.0 BAT:12.0 SOL:13.0',
          'cD': DateFormat('dd/MM/yyyy').format(DateTime.now()),
          'cT': DateFormat('HH:mm:ss').format(DateTime.now()),
        },
      );
      debugPrint('✅ Test publish to device successful');
    } catch (e) {
      debugPrint('❌ Test publish to device failed: $e');
    }
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _initialized,
      'topic': _mqttTopic,
      'subscriptions': _mqttNotifier.getSubscribedTopics(),
      'isConnected': ref.read(mqttProvider).isConnected,
      'hasCallbacks': _mqttNotifier.hasCallbacks(_mqttTopic),
      'callbackCount': _mqttNotifier.getCallbackCount(_mqttTopic),
      'lastMessages': _mqttNotifier.getAllMessages().keys,
    };
  }
}*/
