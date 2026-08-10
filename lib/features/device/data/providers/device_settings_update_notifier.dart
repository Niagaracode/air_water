import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../../core/network/mqtt/mqtt_service.dart';
import '../../../../core/network/mqtt/providers/mqtt_notifier.dart';

import '../../presentation/model/device_setting_update.dart';

// ============================================================
// STATE
// ============================================================

class DeviceSettingsUpdateState {
  final List<DeviceSettingUpdate> settings;
  final bool isUpdating;
  final String? error;

  const DeviceSettingsUpdateState({
    this.settings = const [],
    this.isUpdating = false,
    this.error,
  });

  int get completedCount {
    return settings.where((setting) =>
      setting.status == SettingUpdateStatus.completed,
    ).length;
  }

  int get failedCount {
    return settings.where((setting) =>
      setting.status == SettingUpdateStatus.failed,
    ).length;
  }

  int get sendingCount {
    return settings.where((setting) =>
      setting.status == SettingUpdateStatus.sending,
    ).length;
  }

  int get pendingCount {
    return settings.where((setting) =>
      setting.status == SettingUpdateStatus.pending,
    ).length;
  }

  int get totalCount => settings.length;

  int get finishedCount {
    return completedCount + failedCount;
  }

  bool get allFinished {
    if (settings.isEmpty) {
      return false;
    }

    return settings.every((setting) =>
      setting.status == SettingUpdateStatus.completed ||
          setting.status == SettingUpdateStatus.failed,
    );
  }

  bool get allCompleted {
    return settings.isNotEmpty &&
        settings.every((setting) =>
          setting.status == SettingUpdateStatus.completed,
        );
  }

  DeviceSettingsUpdateState copyWith({
    List<DeviceSettingUpdate>? settings,
    bool? isUpdating,
    String? error,
  }) {
    return DeviceSettingsUpdateState(
      settings: settings ?? this.settings,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
    );
  }
}

// ============================================================
// NOTIFIER
// ============================================================

class DeviceSettingsUpdateNotifier
    extends StateNotifier<DeviceSettingsUpdateState> {

  // ----------------------------------------------------------
  // MQTT NOTIFIER
  // ----------------------------------------------------------

  final MqttNotifier _mqttNotifier;

  // ----------------------------------------------------------
  // MQTT SERVICE
  // ----------------------------------------------------------

  final MqttService _mqttService;

  // ----------------------------------------------------------
  // ACK TOPIC
  // ----------------------------------------------------------

  String? _ackTopic;

  // ----------------------------------------------------------
  // Prevent duplicate callback registration
  // ----------------------------------------------------------

  bool _ackCallbackRegistered = false;

  // ----------------------------------------------------------
  // Device ID currently being updated
  // ----------------------------------------------------------

  String? _currentDeviceId;
  final Set<String> _waitingForAck = {};

  // ----------------------------------------------------------
  // Prevent processing same acknowledgement repeatedly
  // ----------------------------------------------------------

  String? _lastAckSignature;

  // ----------------------------------------------------------
  // Constructor
  // ----------------------------------------------------------

  DeviceSettingsUpdateNotifier(
      this._mqttNotifier,
      this._mqttService,
      ) : super(
    const DeviceSettingsUpdateState(),
  );

  // ==========================================================
  // UPDATE SETTINGS
  // ==========================================================

  Future<void> updateSettings({
    required String deviceId,
    required List<DeviceSettingUpdate> settings,
  }) async {

    if (settings.isEmpty) {
      debugPrint(
        '⚠️ No device settings to update',
      );

      return;
    }

    // --------------------------------------------------------
    // Save current device
    // --------------------------------------------------------

    _currentDeviceId = deviceId;

    // --------------------------------------------------------
    // Clear previous request information
    // --------------------------------------------------------

    _waitingForAck.clear();
    _lastAckSignature = null;

    // --------------------------------------------------------
    // Reset settings
    // --------------------------------------------------------

    for (final setting in settings) {
      setting.status = SettingUpdateStatus.pending;
      setting.error = null;
      setting.sentAt = null;
      setting.completedAt = null;
    }

    // --------------------------------------------------------
    // Set state
    // --------------------------------------------------------

    state = state.copyWith(settings: [...settings],
      isUpdating: true,
      error: null,
    );



    // ========================================================
    // ACK TOPIC
    // ========================================================

    final ackTopic = 'level/$deviceId';

    await _registerAckCallback(
      ackTopic,
    );

    // ========================================================
    // PUBLISH SETTINGS
    // ========================================================

    for (int i = 0; i < settings.length; i++) {

      final setting = settings[i];

      // ------------------------------------------------------
      // Check if notifier is still mounted
      // ------------------------------------------------------

      if (!mounted) {
        return;
      }

      // ------------------------------------------------------
      // Mark as sending
      // ------------------------------------------------------

      _updateStatus(
        setting.id,
        SettingUpdateStatus.sending,
      );

      // ------------------------------------------------------
      // Save sent time
      // ------------------------------------------------------

      setting.sentAt = DateTime.now();

      // ------------------------------------------------------
      // Add to ACK waiting list
      // ------------------------------------------------------

      _waitingForAck.add(
        setting.id,
      );

      // ------------------------------------------------------
      // MQTT topic
      // ------------------------------------------------------

      final topic = 'apptolevel/$deviceId';

      // ------------------------------------------------------
      // Actual IoT payload
      final payload = {'sentSms': setting.value};


      // ======================================================
      // PUBLISH
      try {

        await _mqttService.publishJson(
          topic,
          payload,
        );

        debugPrint(
          '✅ ${setting.name} published successfully',
        );

      } catch (e) {

        debugPrint(
          '❌ Failed to publish ${setting.name}',
        );

        debugPrint(
          '❌ Error: $e',
        );

        // ----------------------------------------------------
        // Mark failed
        // ----------------------------------------------------

        setting.status = SettingUpdateStatus.failed;

        setting.error = 'Publish failed: $e';

        // ----------------------------------------------------
        // Remove from ACK waiting list
        // ----------------------------------------------------

        _waitingForAck.remove(
          setting.id,
        );

        // ----------------------------------------------------
        // Update state
        // ----------------------------------------------------

        state = state.copyWith(
          settings: [...state.settings],
          error: e.toString(),
        );
      }

      // ======================================================
      // WAIT 5 SECONDS
      // ======================================================

      if (i < settings.length - 1) {

        debugPrint(
          '⏳ Waiting 5 seconds before next setting...',
        );

        await Future.delayed(
          const Duration(seconds: 5),
        );
      }
    }

    // ========================================================
    // ALL SETTINGS PUBLISHED
    // ========================================================

    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    debugPrint(
      '📤 ALL SETTINGS HAVE BEEN PUBLISHED',
    );

    debugPrint(
      '📥 Waiting for IoT device acknowledgements...',
    );

    debugPrint(
      '⏳ Waiting settings: $_waitingForAck',
    );

    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    // --------------------------------------------------------
    // IMPORTANT
    //
    // Do NOT set isUpdating false here.
    //
    // We are waiting for MQTT responses.
    // --------------------------------------------------------

    _checkAllSettingsFinished();
  }

  // ==========================================================
  // REGISTER ACK CALLBACK
  // ==========================================================

  Future<void> _registerAckCallback(String ackTopic) async {

    // --------------------------------------------------------
    // If previous topic is different
    // --------------------------------------------------------

    if (_ackTopic != null && _ackTopic != ackTopic && _ackCallbackRegistered) {

      debugPrint(
        '🧹 Removing old ACK callback: $_ackTopic',
      );

      _mqttNotifier.unsubscribeFromTopic(
        _ackTopic!,
        onMessage: _handleAck,
      );

      _ackCallbackRegistered = false;
    }

    // --------------------------------------------------------
    // Already registered
    // --------------------------------------------------------

    if (_ackTopic == ackTopic &&
        _ackCallbackRegistered) {

      debugPrint(
        'ℹ️ ACK callback already registered',
      );

      return;
    }

    // --------------------------------------------------------
    // Ensure MQTT connection
    // --------------------------------------------------------

    await _mqttNotifier.initializeAndConnect();

    // --------------------------------------------------------
    // Subscribe
    //
    // NOTE:
    //
    // If Dashboard already subscribed to level/deviceId,
    // your MqttNotifier should reuse the broker subscription
    // and add this callback.
    // --------------------------------------------------------

    await _mqttNotifier.subscribeToTopic(
      ackTopic,
      onMessage: _handleAck,
    );

    _ackTopic = ackTopic;

    _ackCallbackRegistered = true;

    debugPrint(
      '✅ Settings ACK callback registered',
    );

    debugPrint(
      '📡 ACK Topic: $ackTopic',
    );
  }

  // ==========================================================
  // HANDLE DEVICE ACK
  // ==========================================================

  void _handleAck(MqttMessageModel message) {

    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    debugPrint(
      '📥 DEVICE RESPONSE RECEIVED',
    );

    debugPrint(
      '📌 Raw Payload: ${message.rawPayload}',
    );


    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    final data = message.data;

    // --------------------------------------------------------
    // Make sure response is JSON
    // --------------------------------------------------------

    if (data.isEmpty) {
      debugPrint(
        '⚠️ Empty device response',
      );

      return;
    }

    // --------------------------------------------------------
    // Create ACK signature
    //
    // Used to prevent duplicate MQTT messages from processing
    // the same response twice.
    // --------------------------------------------------------

    final ackSignature = data.toString();

    if (_lastAckSignature == ackSignature) {

      debugPrint(
        '⚠️ Duplicate device response ignored',
      );

      return;
    }

    _lastAckSignature = ackSignature;


    // --------------------------------------------------------
    // Find which setting this response belongs to
    // --------------------------------------------------------

    final setting = _findMatchingSetting(
      data,
    );

    if (setting == null) {

      debugPrint(
        '⚠️ Device response does not match any pending setting',
      );

      return;
    }

    debugPrint(
      '🎯 ACK MATCHED SETTING: ${setting.name}',
    );

    // ========================================================
    // MARK COMPLETED
    // ========================================================

    setting.status = SettingUpdateStatus.completed;

    setting.completedAt = DateTime.now();

    setting.error = null;

    // --------------------------------------------------------
    // Remove from waiting list
    // --------------------------------------------------------

    _waitingForAck.remove(
      setting.id,
    );

    // --------------------------------------------------------
    // Update Riverpod
    // --------------------------------------------------------

    state = state.copyWith(
      settings: [...state.settings],
    );

    debugPrint(
      '✅ ${setting.name} COMPLETED',
    );

    debugPrint(
      '📊 Progress: '
          '${state.completedCount}/${state.totalCount}',
    );

    // --------------------------------------------------------
    // Check all
    // --------------------------------------------------------

    _checkAllSettingsFinished();
  }

  // ==========================================================
  // FIND MATCHING SETTING
  // ==========================================================

  DeviceSettingUpdate? _findMatchingSetting(Map<String, dynamic> data) {

    final responseText = _buildResponseText(data);

    debugPrint(
      '🔎 Searching ACK against: $responseText',
    );

    // --------------------------------------------------------
    // Search only settings waiting for ACK
    // --------------------------------------------------------

    for (final setting in state.settings) {

      if (!_waitingForAck.contains(setting.id)) {
        continue;
      }

      // ------------------------------------------------------
      // Exact / normalized matching
      // ------------------------------------------------------

      if (_isSettingAcknowledged(setting, responseText, data)) {
        return setting;
      }
    }

    return null;
  }

  // ==========================================================
  // BUILD RESPONSE TEXT
  // ==========================================================

  String _buildResponseText(Map<String, dynamic> data) {

    final values = <String>[];

    for (final entry in data.entries) {
      final value = entry.value?.toString() ?? '';
      values.add(value);
    }

    return values.join(' | ').toUpperCase();
  }

  // ==========================================================
  // CHECK WHETHER RESPONSE ACKNOWLEDGES SETTING
  // ==========================================================

  bool _isSettingAcknowledged(
      DeviceSettingUpdate setting,
      String responseText,
      Map<String, dynamic> data,
      ) {

    // --------------------------------------------------------
    // 1. DATE & TIME matching

    if (setting.id == 'DT') {
      final cM = data['cM']?.toString().toUpperCase() ?? '';
      if (cM.contains('DATE&TIME UPDATED')) {
        return true;
      }
    }

    // --------------------------------------------------------
    // 2. DATA INTERVAL special response

    if (setting.id == 'DIN' || setting.name.toUpperCase().contains('DATA INTERVAL')) {
      final cM = data['cM']?.toString().toUpperCase() ?? '';
      if (cM.contains('DATA DELAY')) {
        return true;
      }
    }

    // --------------------------------------------------------
    // 3. PRESSURE LOW

    if (setting.id == 'PL') {
      final cM = data['cM']?.toString().toUpperCase() ?? '';
      if (cM.contains('PRESS LOW SET VALUE')) {
        return true;
      }
    }

    // --------------------------------------------------------
    // 4. SOLAR LOW

    if (setting.id == 'SL') {
      final cM = data['cM']?.toString().toUpperCase() ?? '';
      if (cM.contains('SOLAR LOW VOLT')) {
        return true;
      }
    }

    // --------------------------------------------------------
    // 5. BATTERY LOW

    if (setting.id == 'BL') {
      final cM = data['cM']?.toString().toUpperCase() ?? '';
      if (cM.contains('BATT LOW VOLT')) {
        return true;
      }
    }

    // --------------------------------------------------------
    // 6. GAS LEVEL HIGH

    if (setting.id == 'GLH') {
      final cM = data['cM']?.toString().toUpperCase() ?? '';
      if (cM.contains('HIGH LEVEL SET VALUE')) {
        return true;
      }
    }

    // --------------------------------------------------------
    // 7. GAS LEVEL LOW

    if (setting.id == 'GLL') {
      final cM = data['cM']?.toString().toUpperCase() ?? '';
      if (cM.contains('LOW LEVEL SET VALUE')) {
        return true;
      }
    }

    // --------------------------------------------------------
    // 8. GAS LEVEL CRITICAL

    if (setting.id == 'GCL') {
      final cM = data['cM']?.toString().toUpperCase() ?? '';
      if (cM.contains('CRITICAL LEVEL SET VALUE')) {
        return true;
      }
    }

    // --------------------------------------------------------
    // 9. REORDER LEVEL

    if (setting.id == 'RL') {
      final cM = data['cM']?.toString().toUpperCase() ?? '';
      if (cM.contains(' REORDER LEVEL SET VALUE')) {
        return true;
      }
    }

    // --------------------------------------------------------
    // 10. SENSOR RATING

    if (setting.id == 'SRT') {
      final cM = data['cM']?.toString().toUpperCase() ?? '';
      if (cM.contains('SENSOR RATING')) {
        return true;
      }
    }

    // --------------------------------------------------------
    // No match

    return false;
  }


  // ==========================================================
  // UPDATE STATUS
  // ==========================================================

  void _updateStatus(String id, SettingUpdateStatus status) {

    final index = state.settings.indexWhere((item) => item.id == id);

    if (index == -1) {

      debugPrint(
        '⚠️ Setting not found: $id',
      );

      return;
    }

    final setting = state.settings[index];
    setting.status = status;

    // --------------------------------------------------------
    // Clear error when sending
    // --------------------------------------------------------

    if (status == SettingUpdateStatus.sending) {
      setting.error = null;
    }

    // --------------------------------------------------------
    // Notify UI
    // --------------------------------------------------------

    state = state.copyWith(
      settings: [...state.settings],
    );

    debugPrint(
      '🔄 ${setting.name} → $status',
    );
  }

  // ==========================================================
  // CHECK ALL SETTINGS FINISHED
  // ==========================================================

  void _checkAllSettingsFinished() {

    if (state.settings.isEmpty) {
      return;
    }

    final allFinished =
    state.settings.every((setting) =>
      setting.status == SettingUpdateStatus.completed ||
          setting.status == SettingUpdateStatus.failed,
    );

    if (!allFinished) {

      debugPrint(
        '⏳ Still waiting for device ACK...',
      );

      return;
    }

    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    debugPrint(
      '🎉 ALL SETTINGS ACKNOWLEDGED',
    );

    debugPrint(
      '✅ Completed: ${state.completedCount}',
    );

    debugPrint(
      '❌ Failed: ${state.failedCount}',
    );

    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    state = state.copyWith(
      isUpdating: false,
    );
  }

  // ==========================================================
  // CANCEL
  // ==========================================================

  void cancel() {

    debugPrint(
      '🛑 Cancelling settings update',
    );

    // --------------------------------------------------------
    // Remove callback
    // --------------------------------------------------------

    if (_ackTopic != null &&
        _ackCallbackRegistered) {

      _mqttNotifier.unsubscribeFromTopic(
        _ackTopic!,
        onMessage: _handleAck,
      );

      debugPrint(
        '🧹 Settings ACK callback removed',
      );
    }

    _ackTopic = null;

    _ackCallbackRegistered = false;

    // --------------------------------------------------------
    // Clear pending ACKs
    // --------------------------------------------------------

    _waitingForAck.clear();

    _lastAckSignature = null;

    _currentDeviceId = null;

    // --------------------------------------------------------
    // Stop updating
    // --------------------------------------------------------

    state = state.copyWith(
      isUpdating: false,
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {

    debugPrint(
      '🧹 Disposing DeviceSettingsUpdateNotifier',
    );

    if (_ackTopic != null &&
        _ackCallbackRegistered) {

      _mqttNotifier.unsubscribeFromTopic(
        _ackTopic!,
        onMessage: _handleAck,
      );
    }

    _waitingForAck.clear();

    _lastAckSignature = null;

    super.dispose();
  }
}