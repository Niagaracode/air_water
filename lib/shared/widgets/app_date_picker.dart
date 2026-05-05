import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

/// A date picker field that shows the calendar as an overlay below the field.
class AppDatePickerField extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime?> onDateChanged;
  final String hint;

  const AppDatePickerField({
    super.key,
    this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    this.hint = 'Select Date',
  });

  @override
  State<AppDatePickerField> createState() => _AppDatePickerFieldState();
}

class _AppDatePickerFieldState extends State<AppDatePickerField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late DateTime _currentMonth;
  DateTime? _tempSelected;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      (widget.selectedDate ?? DateTime.now()).year,
      (widget.selectedDate ?? DateTime.now()).month,
    );
    _tempSelected = widget.selectedDate;
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    if (_isDisposed) return;

    _currentMonth = DateTime(
      (widget.selectedDate ?? DateTime.now()).year,
      (widget.selectedDate ?? DateTime.now()).month,
    );
    _tempSelected = widget.selectedDate;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 8),
              child: Material(
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: _DatePickerCalendar(
                    initialMonth: _currentMonth,
                    selectedDate: _tempSelected,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    onCancel: _close,
                    onConfirm: (date) {
                      if (!_isDisposed && mounted) {
                        widget.onDateChanged(date);
                        _close();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);

    if (mounted && !_isDisposed) {
      setState(() => _isOpen = true);
    }
  }

  void _close() {
    if (mounted && !_isDisposed) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isOpen = false);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(widget.selectedDate!)
        : null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen
                  ? const Color(0xFF141E7A)
                  : const Color(0xFFE5E7EB),
              width: _isOpen ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayText ?? widget.hint,
                  style: GoogleFonts.inter(
                    color: displayText != null
                        ? const Color(0xFF111827)
                        : const Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.selectedDate != null)
                GestureDetector(
                  onTap: () {
                    if (mounted && !_isDisposed) {
                      widget.onDateChanged(null);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              Icon(
                Icons.calendar_today_rounded,
                color: _isOpen
                    ? const Color(0xFF141E7A)
                    : const Color(0xFF6B7280),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The calendar portion, used internally by AppDatePickerField overlay.
class _DatePickerCalendar extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime? selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final VoidCallback onCancel;
  final ValueChanged<DateTime?> onConfirm;

  const _DatePickerCalendar({
    required this.initialMonth,
    this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<_DatePickerCalendar> createState() => _DatePickerCalendarState();
}

class _DatePickerCalendarState extends State<_DatePickerCalendar> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
    _selectedDate = widget.selectedDate;
  }

  void _previousMonth() {
    if (mounted && !_isDisposed) {
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      });
    }
  }

  void _nextMonth() {
    if (mounted && !_isDisposed) {
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildWeekdayLabels(),
          const SizedBox(height: 8),
          _buildDayGrid(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    if (!_isDisposed && mounted) {
                      widget.onCancel();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (!_isDisposed && mounted) {
                      widget.onConfirm(_selectedDate);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF141E7A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF111827),
          ),
          onPressed: _previousMonth,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF3F4F6),
            padding: const EdgeInsets.all(8),
          ),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF111827),
          ),
          onPressed: _nextMonth,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF3F4F6),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    final weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map(
            (label) => Expanded(
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildDayGrid() {
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).weekday;

    final offset = firstWeekday - 1;
    final List<Widget> dayWidgets = [];

    // Prev month days
    final lastDayPrevMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      0,
    ).day;
    for (int i = 0; i < offset; i++) {
      final day = lastDayPrevMonth - offset + i + 1;
      dayWidgets.add(_buildDayCell(day, isCurrentMonth: false));
    }

    // Current month days
    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(_buildDayCell(day, isCurrentMonth: true));
    }

    // Next month days
    final totalCells = dayWidgets.length;
    final remaining = (7 - (totalCells % 7)) % 7;
    for (int day = 1; day <= remaining; day++) {
      dayWidgets.add(_buildDayCell(day, isCurrentMonth: false));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          physics: const NeverScrollableScrollPhysics(),
          children: dayWidgets,
        );
      },
    );
  }

  Widget _buildDayCell(int day, {required bool isCurrentMonth}) {
    // Calculate the actual date for this cell
    int monthOffset = 0;
    if (!isCurrentMonth) {
      // Determine if this is from previous or next month
      if (day > 20) {
        monthOffset = -1; // Previous month
      } else {
        monthOffset = 1; // Next month
      }
    }

    final date = DateTime(
      _currentMonth.year,
      _currentMonth.month + monthOffset,
      day,
    );

    final isSelected = _selectedDate != null &&
        date.year == _selectedDate!.year &&
        date.month == _selectedDate!.month &&
        date.day == _selectedDate!.day &&
        isCurrentMonth;

    final isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;

    final bool isDisabled = date.isBefore(widget.firstDate) ||
        date.isAfter(widget.lastDate);

    return GestureDetector(
      onTap: (isCurrentMonth && !isDisabled)
          ? () {
        if (mounted && !_isDisposed) {
          setState(() {
            _selectedDate = date;
          });
        }
      }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF141E7A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: const Color(0xFF141E7A), width: 1)
              : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: GoogleFonts.inter(
              color: isSelected
                  ? Colors.white
                  : isCurrentMonth
                  ? (isDisabled
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFF111827))
                  : const Color(0xFFE5E7EB),
              fontWeight: isSelected || isToday
                  ? FontWeight.w700
                  : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}