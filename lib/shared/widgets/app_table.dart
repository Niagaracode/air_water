import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppTableHeaderCell  — navy header column (fixed width or flex)
// ─────────────────────────────────────────────────────────────────────────────
class AppTableHeaderCell extends StatelessWidget {
  final String label;
  final int? flex;  // You can remove this if not needed elsewhere
  final double? width;
  final TextAlign? textAlign;

  const AppTableHeaderCell(
      this.label, {
        super.key,
        this.flex,
        this.width,
        this.textAlign,
      });

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label.toUpperCase(),
      textAlign: textAlign ?? TextAlign.left,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: Colors.black.withValues(alpha: 0.6),
        letterSpacing: 0.8,
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex ?? 1, child: child);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTableCell  — regular data cell (fixed width or flex)
// ─────────────────────────────────────────────────────────────────────────────
class AppDataTableCell extends StatelessWidget {
  final String? text;
  final Widget? child;
  final int? flex;
  final double? width;
  final bool bold;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;

  const AppDataTableCell(
      this.text, {
        super.key,
        this.child,
        this.flex,
        this.width,
        this.bold = false,
        this.color,
        this.fontSize,
        this.textAlign,
      });

  @override
  Widget build(BuildContext context) {
    Widget content = child ??
        Text(
          text ?? '',
          style: GoogleFonts.inter(
            fontSize: fontSize ?? 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: color ?? (bold ? const Color(0xFF111827) : const Color(0xFF374151)),
          ),
          textAlign: textAlign,
          overflow: TextOverflow.ellipsis,
        );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }

    return Expanded(flex: flex ?? 1, child: content);
  }
}

class AppTableCell extends StatelessWidget {
  final String? text;
  final Widget? child;
  final int? flex;
  final double? width;
  final bool bold;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;
  final int? maxLines; // Add maxLines control

  const AppTableCell(
      this.text, {
        super.key,
        this.child,
        this.flex,
        this.width,
        this.bold = false,
        this.color,
        this.fontSize,
        this.textAlign,
        this.maxLines = 2, // Default to 2 lines
      });

  @override
  Widget build(BuildContext context) {
    Widget content = child ?? Text(
      text ?? '',
      style: GoogleFonts.inter(
        fontSize: fontSize ?? 14,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: color ?? (bold ? const Color(0xFF111827) : const Color(0xFF374151)),
      ),
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
    );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }

    return Expanded(flex: flex ?? 1, child: content);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppStatusBadge  — pill with dot indicator (Active / Inactive)
// ─────────────────────────────────────────────────────────────────────────────
class AppStatusBadge extends StatelessWidget {
  final int? status;

  const AppStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFECFDF5) // More vibrant green bg
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? const Color(0xFF10B981).withValues(alpha: 0.2)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF10B981) // More professional emerald green
                  : const Color(0xFF9CA3AF),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFF065F46) // Darker emerald text
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppRoleBadge  — pill with role-specific colors
// ─────────────────────────────────────────────────────────────────────────────
class AppRoleBadge extends StatelessWidget {
  final String? roleName;

  const AppRoleBadge({super.key, required this.roleName});

  @override
  Widget build(BuildContext context) {
    if (roleName == null || roleName!.isEmpty) {
      return Text(
        '—',
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
      );
    }

    final name = roleName!.trim();
    final upperName = name.toUpperCase().replaceAll('_', ' ');

    Color bg;
    Color border;
    Color text;

    if (upperName.contains('SUPER ADMIN')) {
      bg = const Color(0xFFF5F3FF);
      border = const Color(0xFFDDD6FE);
      text = const Color(0xFF7C3AED);
    } else if (upperName.contains('COMPANY ADMIN')) {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFDBEAFE);
      text = const Color(0xFF2563EB);
    } else if (upperName.contains('DISTRIBUTOR')) {
      bg = const Color(0xFFFFF1F2);
      border = const Color(0xFFFFE4E6);
      text = const Color(0xFFE11D48);
    } else if (upperName.contains('SUPERVISOR')) {
      bg = const Color(0xFFEEF2FF);
      border = const Color(0xFFE0E7FF);
      text = const Color(0xFF4F46E5);
    } else if (upperName.contains('TECHNICIAN') ||
        upperName.contains('TECHNICAL')) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFEF3C7);
      text = const Color(0xFFD97706);
    } else if (upperName.contains('CUSTOMER')) {
      bg = const Color(0xFFF0F9FF);
      border = const Color(0xFFE0F2FE);
      text = const Color(0xFF0369A1);
    } else {
      bg = const Color(0xFFF8FAFC);
      border = const Color(0xFFE2E8F0);
      text = const Color(0xFF475569);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        name,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppImportanceBadge  — pill with importance-specific colors
// ─────────────────────────────────────────────────────────────────────────────
class AppImportanceBadge extends StatelessWidget {
  final String? importance;

  const AppImportanceBadge({super.key, required this.importance});

  @override
  Widget build(BuildContext context) {
    if (importance == null || importance!.isEmpty) {
      return Text(
        '—',
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
      );
    }

    final val = importance!.trim().toLowerCase();
    
    Color bg;
    Color border;
    Color text;

    if (val.contains('critical')) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      text = const Color(0xFFDC2626);
    } else if (val.contains('urgent')) {
      bg = const Color(0xFFF5F3FF);
      border = const Color(0xFFDDD6FE);
      text = const Color(0xFF7C3AED);
    } else if (val.contains('warning')) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFEF3C7);
      text = const Color(0xFFD97706);
    } else if (val.contains('info')) {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFDBEAFE);
      text = const Color(0xFF2563EB);
    } else {
      bg = const Color(0xFFF9FAFB);
      border = const Color(0xFFE5E7EB);
      text = const Color(0xFF4B5563);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        importance!.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTableActionButton  — boxed 30×30 icon button
// ─────────────────────────────────────────────────────────────────────────────
class AppTableActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const AppTableActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 17, color: color),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 20,
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        tooltip: icon == Icons.delete_outline ? 'Delete' : 'Edit',
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTableEmptyState  — centered icon + title + subtitle
// ─────────────────────────────────────────────────────────────────────────────
class AppTableEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AppTableEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = 'Try adjusting your search or filter criteria.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTableBottomCap  — rounded bottom border strip
// ─────────────────────────────────────────────────────────────────────────────
class AppTableBottomCap extends StatelessWidget {
  const AppTableBottomCap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTableLoadingMore  — spinner row shown while fetching next page
// ─────────────────────────────────────────────────────────────────────────────
class AppTableLoadingMore extends StatelessWidget {
  const AppTableLoadingMore({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF141E7A),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading more records...',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTableInitialLoader  — full-area spinner for first load
// ─────────────────────────────────────────────────────────────────────────────
class AppTableInitialLoader extends StatelessWidget {
  const AppTableInitialLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48.0),
      child: Center(child: CircularProgressIndicator(color: Color(0xFF141E7A))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTable  — legacy generic table (kept for backward compatibility)
// ─────────────────────────────────────────────────────────────────────────────
class AppTable extends StatelessWidget {
  final List<String> headers;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;

  const AppTable({
    super.key,
    required this.headers,
    required this.itemCount,
    required this.itemBuilder,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          if (itemCount == 0 && !isLoading)
            _buildEmptyState()
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    ColoredBox(
                      color: index.isEven
                          ? Colors.white
                          : const Color(0xFFF9FAFB),
                      child: itemBuilder(context, index),
                    ),
                    if (index < itemCount - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF3F4F6),
                      ),
                  ],
                );
              },
            ),
            if (hasMore) _buildLoadMore(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
        ),
      ),
      child: Row(
        children: headers
            .map(
              (header) => Expanded(
                child: Text(
                  header.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.90),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 32,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No records found',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search or filter criteria.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF141E7A),
                ),
              )
            : TextButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: Color(0xFF141E7A),
                ),
                label: Text(
                  'Load More',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF141E7A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
      ),
    );
  }
}
