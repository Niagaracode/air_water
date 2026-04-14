class MqttConnectionStateModel {
  final bool isConnected;
  final String? error;
  final DateTime? lastConnectedAt;
  final bool isConnecting;

  const MqttConnectionStateModel({
    required this.isConnected,
    this.error,
    this.lastConnectedAt,
    this.isConnecting = false,
  });

  MqttConnectionStateModel copyWith({
    bool? isConnected,
    String? error,
    DateTime? lastConnectedAt,
    bool? isConnecting,
  }) {
    return MqttConnectionStateModel(
      isConnected: isConnected ?? this.isConnected,
      error: error ?? this.error,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      isConnecting: isConnecting ?? this.isConnecting,
    );
  }
}