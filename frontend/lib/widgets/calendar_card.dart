import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarCard extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final VoidCallback onClose;
  final Color? accentColor;

  const CalendarCard({
    Key? key,
    required this.focusedDay,
    this.rangeStart,
    this.rangeEnd,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onClose,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccentColor = accentColor ?? const Color(0xFFA15C20);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('select_date'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,
              rangeStartDay: rangeStart,
              rangeEndDay: rangeEnd,
              locale: context.locale.toString(),
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                    color: effectiveAccentColor.withAlpha((0.5 * 255).toInt()), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                    color: effectiveAccentColor, shape: BoxShape.circle),
                rangeStartDecoration: BoxDecoration(
                    color: effectiveAccentColor, shape: BoxShape.circle),
                rangeEndDecoration: BoxDecoration(
                    color: effectiveAccentColor, shape: BoxShape.circle),
                rangeHighlightColor: effectiveAccentColor.withAlpha((0.5 * 255).toInt()),
              ),
              headerStyle: const HeaderStyle(
                  formatButtonVisible: false, titleCentered: true),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveAccentColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: onClose,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('select_date'.tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
