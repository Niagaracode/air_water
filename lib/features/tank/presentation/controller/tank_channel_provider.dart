import 'package:flutter_riverpod/legacy.dart';
import '../../data/model/tank_channel_model.dart';
import '../../data/tank_repository.dart';
import 'tank_provider.dart';

final tankChannelProvider =
StateNotifierProvider.autoDispose.family<
    TankChannelNotifier,
    TankChannelState,
    int>((ref, tankId) {

  return TankChannelNotifier(
    ref.read(tankRepositoryProvider),
    tankId,
  );
});


class TankChannelState {
  final bool isLoading;
  final List<TankChannelModel> channels;
  final String? error;

  const TankChannelState({
    this.isLoading = false,
    this.channels = const [],
    this.error,
  });

  TankChannelState copyWith({bool? isLoading,
    List<TankChannelModel>? channels, String? error}) {
    return TankChannelState(
      isLoading: isLoading ?? this.isLoading,
      channels: channels ?? this.channels,
      error: error,
    );
  }
}

class TankChannelNotifier extends StateNotifier<TankChannelState> {

  final TankRepository repository;
  final int tankId;

  TankChannelNotifier(this.repository, this.tankId) :
        super(const TankChannelState()) {
    loadChannels();
  }

  Future<void> loadChannels() async {

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {

      final channels =
      await repository.getTankChannels(tankId);

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        channels: [...channels],
      );

    } catch (e) {

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}