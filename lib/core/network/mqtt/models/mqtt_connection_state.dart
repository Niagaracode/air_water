const _unset = Object();

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
    Object? error = _unset, // sentinel lets us pass error:null to CLEAR it
    DateTime? lastConnectedAt,
    bool? isConnecting,
  }) {
    return MqttConnectionStateModel(
      isConnected: isConnected ?? this.isConnected,
      error: identical(error, _unset) ? this.error : error as String?,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      isConnecting: isConnecting ?? this.isConnecting,
    );
  }
}