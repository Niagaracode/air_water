import 'package:flutter/material.dart';

import '../../core/app_theme/app_theme.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key});

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: 61,
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
                color: Colors.grey.shade200,
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
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              IconButton(
                onPressed: () {},
                icon: Badge(
                  label: Text('2'),
                  child: Icon(Icons.notifications_none_rounded,
                      color: primary),
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined),
              ),

              const SizedBox(width: 24),

              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?u=danielle',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Danielle Campbell',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}