import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/sidebar_provider.dart';

class SidebarHeader extends ConsumerWidget {
  final bool isExpanded;

  const SidebarHeader({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: isExpanded ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/png/app_logo_white.png',
            height: 36,
          ),
          IconButton(
            icon: const Icon(
                Icons.keyboard_double_arrow_left),
            color: primaryColor,
            onPressed: () {
              ref
                  .read(sidebarExpandedProvider.notifier)
                  .toggle();
            },
          ),
        ],
      ) : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/png/app_logo.png',
              height: 28,
            ),
          ),
          const SizedBox(height: 12),
          IconButton(
            icon: const Icon(
                Icons.keyboard_double_arrow_right),
            color: primaryColor,
            onPressed: () {
              ref
                  .read(sidebarExpandedProvider.notifier)
                  .toggle();
            },
          ),
        ],
      ),
    );
  }
}
