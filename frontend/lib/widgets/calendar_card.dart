import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class CalendarCard extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? initialRangeStart;
  final DateTime? initialRangeEnd;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Function(DateTime, DateTime)? onDaySelected;
  final Function(DateTime)? onPageChanged;
  final VoidCallback onClose;
  final Color? accentColor;
  final EdgeInsetsGeometry? margin;

  const CalendarCard({
    Key? key,
    required this.focusedDay,
    this.initialRangeStart,
    this.initialRangeEnd,
    this.rangeStart,
    this.rangeEnd,
    this.onDaySelected,
    this.onPageChanged,
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
  bool _isSelectingStart = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay;
    _rangeStart = widget.initialRangeStart ?? widget.rangeStart;
    _rangeEnd = widget.initialRangeEnd ?? widget.rangeEnd;

    if (_rangeStart != null && _rangeEnd != null) {
      _isSelectingStart = true;
    } else if (_rangeStart != null) {
      _isSelectingStart = false;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int _calculateDays() {
    if (_rangeStart == null || _rangeEnd == null) return 0;
    return _rangeEnd!.difference(_rangeStart!).inDays + 1;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    if (selectedDay.isBefore(todayStart)) {
      _showErrorDialog('Vui lòng chọn ngày từ hôm nay trở đi');
      return;
    }

    setState(() {
      _focusedDay = focusedDay;

      if (_isSelectingStart) {
        _rangeStart = selectedDay;
        _rangeEnd = null;
        _isSelectingStart = false;
        print('📅 Chọn ngày bắt đầu: ${DateFormat('yyyy-MM-dd').format(selectedDay)}');
      } else {
        _rangeEnd = selectedDay;

        if (_rangeStart != null && _rangeEnd!.isBefore(_rangeStart!)) {
          print('🔄 Đảo ngược: end < start');
          final temp = _rangeStart;
          _rangeStart = _rangeEnd;
          _rangeEnd = temp;
        }

        _isSelectingStart = true;
        print('📅 Chọn ngày kết thúc: ${DateFormat('yyyy-MM-dd').format(selectedDay)}');
        print('📅 Range: $_rangeStart → $_rangeEnd');
      }
    });

    // Gọi callback nếu có
    widget.onDaySelected?.call(selectedDay, focusedDay);
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });

    // Gọi callback nếu có
    widget.onPageChanged?.call(focusedDay);
  }

  Map<String, String?> _parseErrorMessage(String rawMessage) {
    String groupName = '';
    String dateRange = '';

    final groupMatch = RegExp(r"nhóm '([^']+)'").firstMatch(rawMessage);
    if (groupMatch != null) {
      groupName = groupMatch.group(1) ?? '';
    }

    final dateMatch = RegExp(r'\[(\d{4}-\d{2}-\d{2}),(\d{4}-\d{2}-\d{2})\)').firstMatch(rawMessage);
    if (dateMatch != null) {
      try {
        final start = DateTime.parse(dateMatch.group(1)!);
        final end = DateTime.parse(dateMatch.group(2)!);

        dateRange = '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
      } catch (e) {
        dateRange = '';
      }
    }

    return {'groupName': groupName, 'dateRange': dateRange};
  }

  void _showErrorDialog(String message) {
    final parsed = _parseErrorMessage(message);
    final isDateConflict = parsed['groupName']?.isNotEmpty == true;
    final isTokenError = message.toLowerCase().contains("token");

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDateConflict ? Icons.calendar_today : Icons.error_outline,
                  size: 48,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isTokenError
                    ? 'Phiên đăng nhập hết hạn'
                    : (isDateConflict ? 'Trùng lịch trình!' : 'Không thể lưu'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),

              const SizedBox(height: 12),

              if (isTokenError)
                Text(
                  'Phiên đăng nhập của bạn đã hết hạn.\nVui lòng đăng nhập lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                )
              else if (isDateConflict)
                _buildDateConflictUI(parsed)
              else
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    isTokenError ? 'Đăng nhập lại' : 'Đã hiểu',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateConflictUI(Map parsed) {
    return Column(
      children: [
        Text(
          'Bạn đang tham gia nhóm',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Text(
            parsed['groupName']!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'có lịch trình',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.date_range, size: 18, color: Colors.orange.shade700),
            const SizedBox(width: 6),
            Text(
              parsed['dateRange']!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          'Vui lòng chọn ngày khác hoặc rời khỏi nhóm để cập nhật lịch trình mới.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Thành công!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Lịch trình của bạn đã được lưu thành công',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),

              if (_rangeStart != null && _rangeEnd != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(_rangeStart!)} - ${DateFormat('dd/MM/yyyy').format(_rangeEnd!)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClose();
                  },
                  child: const Text(
                    'Hoàn tất',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSelectedDates() async {
    if (_rangeStart == null || _rangeEnd == null) {
      _showErrorDialog('Vui lòng chọn đầy đủ ngày bắt đầu và kết thúc');
      return;
    }

    setState(() => _isLoading = true);

    final String startStr = DateFormat('yyyy-MM-dd').format(_rangeStart!);
    final String endStr = DateFormat('yyyy-MM-dd').format(_rangeEnd!);
    final String daterange = '[$startStr,$endStr)';

    print('📅 Sending daterange: $daterange');
    print('   User chọn: ${DateFormat('dd/MM/yyyy').format(_rangeStart!)} → ${DateFormat('dd/MM/yyyy').format(_rangeEnd!)}');

    try {
      final accessToken = await AuthService.getValidAccessToken();
      final url = ApiConfig.getUri(ApiConfig.userProfile);

      final resp = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'travel_dates': daterange}),
      );

      print('📡 Response status: ${resp.statusCode}');
      print('📡 Response body: ${resp.body}');

      setState(() => _isLoading = false);

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        _showSuccessDialog();
      } else {
        final body = resp.body.isNotEmpty ? resp.body : resp.statusCode.toString();

        String errorMessage = 'Đã xảy ra lỗi khi lưu lịch trình';
        try {
          final jsonBody = jsonDecode(body);
          errorMessage = jsonBody['detail'] ?? errorMessage;
        } catch (e) {
          errorMessage = body;
        }

        _showErrorDialog(errorMessage);
        print('❌ Error: $body');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Exception: $e');
      _showErrorDialog('Không thể kết nối đến server. Vui lòng thử lại sau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccentColor = widget.accentColor ?? const Color(0xFFA15C20);
    final int tripDays = _calculateDays();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

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

            // Hướng dẫn chọn ngày
            Text(
              _isSelectingStart
                  ? 'Chọn ngày bắt đầu'
                  : 'Chọn ngày kết thúc',
              style: TextStyle(
                fontSize: 14,
                color: effectiveAccentColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'WorkSans',
              ),
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
              firstDay: todayStart,
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              locale: context.locale.toString(),
              onDaySelected: _onDaySelected,
              onPageChanged: _onPageChanged,
              enabledDayPredicate: (day) {
                return !day.isBefore(todayStart);
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
                disabledTextStyle: TextStyle(color: Colors.grey.shade300),
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
                onPressed: (_rangeStart != null && _rangeEnd != null && !_isLoading)
                    ? _saveSelectedDates
                    : null,
                child: _isLoading
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
}
