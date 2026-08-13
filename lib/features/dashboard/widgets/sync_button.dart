import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_theme/app_theme.dart';

class SyncButton extends StatefulWidget {
  const SyncButton({
    super.key,
    required this.onSync,
    this.label = 'Sync Now',
    this.syncingLabel = 'Syncing...',
    this.icon = Icons.refresh_rounded,
    this.foregroundColor = Colors.white,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.isNarrow = false,
    this.browserStyle = false,
  });

  final Future<void> Function() onSync;
  final String label;
  final String syncingLabel;
  final IconData icon;
  final Color foregroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isNarrow;

  /// When true, renders as a plain circular icon button like a browser's
  /// reload button (transparent, subtle grey on hover/press) instead of a
  /// filled colored pill.
  final bool browserStyle;

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton>
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });
    _spinController.repeat();

    try {
      await widget.onSync();
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      if (mounted) {
        _spinController
          ..stop()
          ..reset();
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.browserStyle) {
      return Tooltip(
        message: _isSyncing ? widget.syncingLabel : widget.label,
        child: Material(
          color: primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isSyncing ? null : _handleSync,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: RotationTransition(
                turns: _spinController,
                child: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return IconButton(
      onPressed: _isSyncing ? null : _handleSync,
      style: IconButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),
      icon: RotationTransition(
        turns: _spinController,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}