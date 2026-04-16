// Dummy Alarms Data Model
import 'package:flutter_riverpod/legacy.dart';

class AlarmModel {
  final String id;
  final String type;
  final String message;
  final String severity; // 'Critical', 'Warning', 'Info'
  final String tankId;
  final String tankName;
  final String siteName;
  final DateTime timestamp;
  final bool isAcknowledged;

  AlarmModel({
    required this.id,
    required this.type,
    required this.message,
    required this.severity,
    required this.tankId,
    required this.tankName,
    required this.siteName,
    required this.timestamp,
    this.isAcknowledged = false,
  });
}

// Dummy Alarms Data Provider
final alarmProviderDashboard = StateNotifierProvider<AlarmNotifier, List<AlarmModel>>((ref) {
  return AlarmNotifier();
});

class AlarmNotifier extends StateNotifier<List<AlarmModel>> {
  AlarmNotifier() : super(_generateDummyAlarms());

  static List<AlarmModel> _generateDummyAlarms() {
    return [
      AlarmModel(
        id: 'AL001',
        type: 'Low Level',
        message: 'Oxygen tank level below 20% threshold',
        severity: 'Critical',
        tankId: 'T004',
        tankName: 'Emergency Reserve',
        siteName: 'Tucson Medical Center',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      AlarmModel(
        id: 'AL002',
        type: 'Warning',
        message: 'Nitrogen tank pressure fluctuation detected',
        severity: 'Warning',
        tankId: 'T002',
        tankName: 'Reserve Oxygen Tank',
        siteName: 'Phoenix Medical Center',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      AlarmModel(
        id: 'AL003',
        type: 'Connection Lost',
        message: 'Device offline for more than 1 hour',
        severity: 'Critical',
        tankId: 'T005',
        tankName: 'Oxygen Tank',
        siteName: 'Sierra Vista Regional',
        timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      ),
      AlarmModel(
        id: 'AL004',
        type: 'Maintenance Required',
        message: 'Scheduled maintenance overdue by 2 days',
        severity: 'Warning',
        tankId: 'T008',
        tankName: 'Oxygen Reserve',
        siteName: 'Carlsbad Medical Center',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      AlarmModel(
        id: 'AL005',
        type: 'Critical Low',
        message: 'Oxygen level critically low at 8.2%',
        severity: 'Critical',
        tankId: 'T010',
        tankName: 'Oxygen Tank',
        siteName: 'Clovis Medical Center',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      AlarmModel(
        id: 'AL006',
        type: 'Temperature Alert',
        message: 'Tank temperature outside normal range',
        severity: 'Warning',
        tankId: 'T014',
        tankName: 'Emergency Oxygen',
        siteName: 'Houston Methodist',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      AlarmModel(
        id: 'AL007',
        type: 'Device Offline',
        message: 'Tank not responding to ping requests',
        severity: 'Critical',
        tankId: 'T015',
        tankName: 'Nitrogen Tank',
        siteName: 'Abilene Regional',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AlarmModel(
        id: 'AL008',
        type: 'Pressure Drop',
        message: 'Sudden pressure drop detected',
        severity: 'Critical',
        tankId: 'T023',
        tankName: 'Emergency Tank',
        siteName: 'Chickasaw Nation Health Center',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      AlarmModel(
        id: 'AL009',
        type: 'Low Level Warning',
        message: 'Tank level below 30%',
        severity: 'Warning',
        tankId: 'T017',
        tankName: 'Reserve Tank',
        siteName: 'Odessa Medical Center',
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      AlarmModel(
        id: 'AL010',
        type: 'Sensor Error',
        message: 'Level sensor malfunction detected',
        severity: 'Warning',
        tankId: 'T022',
        tankName: 'Nitrogen Tank',
        siteName: 'Choctaw Nation Medical',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  // Get unacknowledged alarms
  List<AlarmModel> getUnacknowledgedAlarms() {
    return state.where((alarm) => !alarm.isAcknowledged).toList();
  }

  // Get alarms by severity
  List<AlarmModel> getAlarmsBySeverity(String severity) {
    return state.where((alarm) => alarm.severity == severity).toList();
  }

  // Add new alarm
  void addAlarm(AlarmModel alarm) {
    state = [alarm, ...state];
  }

  // Acknowledge alarm
  void acknowledgeAlarm(String alarmId) {
    state = state.map((alarm) {
      if (alarm.id == alarmId) {
        return AlarmModel(
          id: alarm.id,
          type: alarm.type,
          message: alarm.message,
          severity: alarm.severity,
          tankId: alarm.tankId,
          tankName: alarm.tankName,
          siteName: alarm.siteName,
          timestamp: alarm.timestamp,
          isAcknowledged: true,
        );
      }
      return alarm;
    }).toList();
  }

  // Clear all alarms
  void clearAlarms() {
    state = [];
  }
}