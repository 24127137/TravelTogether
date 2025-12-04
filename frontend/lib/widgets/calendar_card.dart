import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CalendarCard extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final VoidCallback onClose;
  final Color? accentColor;
  final EdgeInsetsGeometry? margin;

  const CalendarCard({
    Key? key,
    required this.focusedDay,
    this.rangeStart,
    this.rangeEnd,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onClose,
    this.accentColor,
    this.margin,
  }) : super(key: key);

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay;
    _rangeStart = widget.rangeStart;
    _rangeEnd = widget.rangeEnd;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int _calculateDays() {
    if (_rangeStart == null || _rangeEnd == null) return 0;
    return _rangeEnd!.difference(_rangeStart!).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccentColor = widget.accentColor ?? const Color(0xFFA15C20);
    final int tripDays = _calculateDays();

    return Card(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header với tiêu đề
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'select_date'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'WorkSans',
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Hiển thị ngày đã chọn
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: effectiveAccentColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: effectiveAccentColor.withAlpha(50),
                ),
              ),
              child: Row(
                children: [
                  // Ngày bắt đầu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'departure'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'WorkSans',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_rangeStart),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _rangeStart != null
                                ? effectiveAccentColor
                                : Colors.grey,
                            fontFamily: 'WorkSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon mũi tên
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward,
                      color: effectiveAccentColor,
                      size: 20,
                    ),
                  ),
                  // Ngày kết thúc
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'return'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'WorkSans',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_rangeEnd),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _rangeEnd != null
                                ? effectiveAccentColor
                                : Colors.grey,
                            fontFamily: 'WorkSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Số ngày đi
            if (tripDays > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: effectiveAccentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$tripDays ${'days'.tr()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'WorkSans',
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Calendar
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: _rangeSelectionMode,
              locale: context.locale.toString(),
              onRangeSelected: (start, end, focusedDay) {
                setState(() {
                  _rangeStart = start;
                  _rangeEnd = end;
                  _focusedDay = focusedDay;
                });
                if (start != null) {
                  widget.onDaySelected(start, focusedDay);
                }
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  if (_rangeStart == null ||
                      (_rangeStart != null && _rangeEnd != null)) {
                    // Bắt đầu chọn mới
                    _rangeStart = selectedDay;
                    _rangeEnd = null;
                  } else {
                    // Đã có start, chọn end
                    if (selectedDay.isBefore(_rangeStart!)) {
                      _rangeEnd = _rangeStart;
                      _rangeStart = selectedDay;
                    } else {
                      _rangeEnd = selectedDay;
                    }
                  }
                  _focusedDay = focusedDay;
                });
                widget.onDaySelected(selectedDay, focusedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
                widget.onPageChanged(focusedDay);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: effectiveAccentColor.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: effectiveAccentColor,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  color: effectiveAccentColor,
                  shape: BoxShape.circle,
                ),
                rangeStartDecoration: BoxDecoration(
                  color: effectiveAccentColor,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: effectiveAccentColor,
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor: effectiveAccentColor.withAlpha(50),
                withinRangeTextStyle: TextStyle(
                  color: effectiveAccentColor,
                  fontWeight: FontWeight.w500,
                ),
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: Colors.red),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'WorkSans',
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: effectiveAccentColor,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: effectiveAccentColor,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nút xác nhận
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_rangeStart != null && _rangeEnd != null)
                      ? effectiveAccentColor
                      : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                onPressed: (_rangeStart != null && _rangeEnd != null && !_isSaving)
                    ? _saveSelectedDates
                    : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'confirm'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'WorkSans',
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Hướng dẫn chọn ngày
            if (_rangeStart == null || _rangeEnd == null) ...[
              const SizedBox(height: 12),
              Text(
                _rangeStart == null
                    ? 'tap_to_select_start'.tr()
                    : 'tap_to_select_end'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'WorkSans',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveSelectedDates() async {
    if (_rangeStart == null || _rangeEnd == null) return;

    setState(() => _isSaving = true);

    final String startStr = _rangeStart!.toIso8601String().split('T')[0];
    final String endStr = _rangeEnd!.toIso8601String().split('T')[0];
    final String daterange = '[$startStr,$endStr)';

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final url = ApiConfig.getUri(ApiConfig.userProfile);

      final resp = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'travel_dates': daterange}),
      );

      setState(() => _isSaving = false);

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('dates_saved'.tr()),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          widget.onClose();
        }
      } else {
        final body =
            resp.body.isNotEmpty ? resp.body : resp.statusCode.toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('save_failed'.tr() + ': ' + body),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('save_failed'.tr() + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
