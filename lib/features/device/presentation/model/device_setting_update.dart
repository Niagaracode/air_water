enum SettingUpdateStatus {
  pending,
  sending,
  completed,
  failed,
}

class DeviceSettingUpdate {
  final String id;
  final String name;
  final String value;

  SettingUpdateStatus status;

  String? error;
  DateTime? sentAt;
  DateTime? completedAt;

  DeviceSettingUpdate({
    required this.id,
    required this.name,
    required this.value,
    this.status = SettingUpdateStatus.pending,
    this.error,
    this.sentAt,
    this.completedAt,
  });
}