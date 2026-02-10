import 'package:flutter_riverpod/flutter_riverpod.dart';

class SidebarNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }
}

final sidebarExpandedProvider = NotifierProvider<SidebarNotifier, bool>(
  SidebarNotifier.new,
);
