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
    return Container(
      color: Colors.white,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 63,
        padding: EdgeInsets.symmetric(
          horizontal: isExpanded ? 16 : 0,
        ),
        child: isExpanded ?
        Row(
          children: [
            Image.asset(
              'assets/png/app_logo_white.png',
              height: 32,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(
                Icons.keyboard_double_arrow_left_rounded,
                size: 20,
              ),
              color: Colors.black.withValues(alpha: 0.60),
              splashRadius: 20,
              onPressed: () {
                ref.read(sidebarExpandedProvider.notifier).toggle();
              },
            ),
          ],
        ) :
        Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              ref.read(sidebarExpandedProvider.notifier).toggle();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.keyboard_double_arrow_right_rounded,
                size: 18,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
