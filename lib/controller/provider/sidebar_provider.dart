import 'package:flutter_riverpod/flutter_riverpod.dart';

class SidebarProvider extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() {
    state = !state;
  }
}

final sidebarExpandedProvider =
NotifierProvider<SidebarProvider, bool>(SidebarProvider.new);
