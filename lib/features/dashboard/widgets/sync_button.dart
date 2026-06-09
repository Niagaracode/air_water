import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SyncButton extends StatefulWidget {
  const SyncButton({
    super.key,
    required this.onSync,
    this.label = 'Sync Now',
    this.syncingLabel = 'Syncing...',
    this.icon = Icons.sync,
    this.backgroundColor = const Color(0xFF141E7A),
    this.foregroundColor = Colors.white,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final Future<void> Function() onSync;
  final String label;
  final String syncingLabel;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      await widget.onSync();
    } catch (e) {
      print('Sync error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isSyncing ? null : _handleSync,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        elevation: 2,
        shadowColor: widget.backgroundColor.withValues(alpha: 0.3),
        padding: widget.padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        disabledBackgroundColor: widget.backgroundColor.withValues(alpha: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSyncing)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(widget.foregroundColor),
              ),
            )
          else
            Icon(widget.icon, size: 14),
          const SizedBox(width: 8),
          Text(
            _isSyncing ? widget.syncingLabel : widget.label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}