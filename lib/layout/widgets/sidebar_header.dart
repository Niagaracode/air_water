import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/core/user_config/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../../config/app_config.dart';
import '../../layout/provider/sidebar_provider.dart';


class SidebarHeader extends ConsumerWidget {
  final bool isExpanded;
  final UserRole userRole;

  const SidebarHeader({
    super.key,
    required this.isExpanded,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 65,
      width: isExpanded ? 250 : 72,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 65,
        padding: EdgeInsets.symmetric(
          horizontal: isExpanded ? 16 : 0,
        ),
        child: isExpanded ?
        Row(
          children: [
            SvgPicture.asset(
              AppConfig.current.appLogoPath,
              height: 32,
              fit: BoxFit.contain,
            ),
            if(userRole != UserRole.customer)...[
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.menu_open,
                  size: 20,
                  color: primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: primary.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  ref.read(sidebarExpandedProvider.notifier).toggle();
                },
              )
            ]
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
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.menu_open,
                size: 18,
                color: primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}