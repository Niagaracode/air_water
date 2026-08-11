import 'package:flutter_riverpod/legacy.dart';
import '../../data/model/sent_and_received_model.dart';
import '../../data/tank_repository.dart';
import 'tank_provider.dart';

final tankSentAndReceivedProvider = StateNotifierProvider.autoDispose.family<
    TankSentAndReceivedNotifier,
    TankSentAndReceivedState,
    int>((ref, tankId) {

  return TankSentAndReceivedNotifier(
    ref.read(tankRepositoryProvider),
    tankId,
  );
});


class TankSentAndReceivedState {
  final bool isLoading;
  final List<SentAndReceivedModel> sentAndRec;
  final String? error;

  const TankSentAndReceivedState({
    this.isLoading = false,
    this.sentAndRec = const [],
    this.error,
  });

  TankSentAndReceivedState copyWith({bool? isLoading,
    List<SentAndReceivedModel>? message, String? error}) {
    return TankSentAndReceivedState(
      isLoading: isLoading ?? this.isLoading,
      sentAndRec: message ?? sentAndRec,
      error: error,
    );
  }
}

class TankSentAndReceivedNotifier extends StateNotifier<TankSentAndReceivedState> {

  final TankRepository repository;
  final int tankId;

  TankSentAndReceivedNotifier(this.repository, this.tankId) :
        super(const TankSentAndReceivedState()) {
    loadChannels();
  }

  Future<void> loadChannels() async {

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {

      final sentAndReceived = await repository.getTankSentAndReceived(tankId);

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        message: [...sentAndReceived],
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