import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme/app_theme.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';


class ScreenHeader extends ConsumerWidget {
  const ScreenHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final userNameAsync = ref.watch(userNameProvider);

    return SizedBox(
      height: 64,
      width: double.infinity,
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [

              Expanded(
                child: Container(
                  height: 48,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              IconButton(
                onPressed: () {},
                icon: Badge(
                  label: const Text('2'),
                  child: Icon(Icons.notifications_none_rounded,
                      color: primary),
                ),
              ),

              const SizedBox(width: 24),

              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await ref.read(authControllerProvider.notifier)
                        .logout();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 5, top: 3, bottom: 3),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 17),
                      const SizedBox(width: 12),
                      userNameAsync.when(
                        data: (name) => Text(
                          name ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        loading: () => const Text('Loading...'),
                        error: (_, __) => const Text('User'),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Profile'),
                    ),
                  ),
                  PopupMenuDivider(height: 0),
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}