import 'package:flutter_riverpod/legacy.dart';

/// Search query for the top header's global search bar only.
/// Keep this separate from any dashboard/list-specific search state.
final headerSearchProvider = StateProvider<String>((ref) => '');