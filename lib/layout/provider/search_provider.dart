import 'package:flutter_riverpod/legacy.dart';

/// Global search query, set from the header's search bar and
/// consumed by any page (e.g. the dashboard's SearchAndFilters)
/// that wants to react to it.
final globalSearchProvider = StateProvider<String>((ref) => '');