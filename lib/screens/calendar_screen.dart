// calendar_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CalendarEvent {
  final String title;
  final String description;
  final DateTime date;
  final Color color;
  final String? hijriDate;

  const CalendarEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.color,
    this.hijriDate,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        // ignore: deprecated_member_use
        'color': color.value,
        'hijriDate': hijriDate,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        title: json['title'],
        description: json['description'],
        date: DateTime.parse(json['date']),
        color: Color(json['color']),
        hijriDate: json['hijriDate'],
      );
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late Map<DateTime, List<CalendarEvent>> _events;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = false;

  final Color primaryColor = const Color(0xFF6B8F7F);
  final Color backgroundColor = const Color(0xFFD9D9D9);

  static const Map<String, String> arabicNumbers = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _events = {};
    _loadEvents();
  }

  String _toArabicNumbers(String number) {
    String result = number;
    arabicNumbers.forEach((english, arabic) {
      result = result.replaceAll(english, arabic);
    });
    return result;
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      await _loadCachedEvents();

      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString('last_calendar_update');
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (lastUpdate == null || _shouldUpdate(lastUpdate)) {
        await _fetchEventsFromAPI();
        await prefs.setString('last_calendar_update', today);
      }
    } catch (e) {
      _loadDefaultEvents();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _shouldUpdate(String lastUpdateStr) {
    try {
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final daysDiff = DateTime.now().difference(lastUpdate).inDays;
      return daysDiff >= 30;
    } catch (e) {
      return true;
    }
  }

  Future<void> _fetchEventsFromAPI() async {
    try {
      final currentYear = DateTime.now().year;
      final nextYear = currentYear + 1;

      final events = <CalendarEvent>[];

      for (var year in [currentYear, nextYear]) {
        final response = await http
            .get(
              Uri.parse('https://api.aladhan.com/v1/gToHCalendar/$year'),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['data'] != null) {
            _processAPIData(data['data'], events, year);
          }
        }
      }

      if (events.isNotEmpty) {
        await _saveEventsToCache(events);

        _organizeEvents(events);

        debugPrint('✅ تم جلب ${events.length} حدث من الإنترنت');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم تحديث التقويم بنجاح'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب البيانات من API: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ فشل التحديث، سيتم استخدام البيانات المحفوظة'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _processAPIData(
      List<dynamic> data, List<CalendarEvent> events, int year) {
    final importantEvents = {
      '1-1': {'title': 'رأس السنة الهجرية', 'color': Colors.blue.shade300},
      '1-10': {'title': 'يوم عاشوراء', 'color': Colors.red.shade300},
      '3-12': {'title': 'المولد النبوي الشريف', 'color': Colors.green.shade300},
      '7-27': {
        'title': 'ليلة الإسراء والمعراج',
        'color': Colors.purple.shade300
      },
      '8-15': {'title': 'ليلة النصف من شعبان', 'color': Colors.indigo.shade300},
      '9-1': {'title': 'أول رمضان', 'color': Colors.teal.shade400},
      '9-27': {'title': 'ليلة القدر', 'color': Colors.deepPurple.shade600},
      '10-1': {'title': 'عيد الفطر المبارك', 'color': Colors.amber.shade400},
      '12-9': {'title': 'يوم عرفة', 'color': Colors.orange.shade500},
      '12-10': {
        'title': 'عيد الأضحى المبارك',
        'color': Colors.deepOrange.shade400
      },
    };

    for (var monthData in data) {
      if (monthData is List) {
        for (var dayData in monthData) {
          try {
            final gregorian = dayData['gregorian'];
            final hijri = dayData['hijri'];

            if (gregorian != null && hijri != null) {
              final date = DateFormat('dd-MM-yyyy').parse(gregorian['date']);
              final hijriKey = '${hijri['month']['number']}-${hijri['day']}';

              if (importantEvents.containsKey(hijriKey)) {
                final eventInfo = importantEvents[hijriKey]!;

                events.add(CalendarEvent(
                  title: eventInfo['title'] as String,
                  description:
                      '${hijri['day']} ${hijri['month']['ar']} ${hijri['year']} هـ',
                  date: date,
                  color: eventInfo['color'] as Color,
                  hijriDate:
                      '${hijri['day']}-${hijri['month']['number']}-${hijri['year']}',
                ));
              }
            }
          } catch (e) {
            debugPrint('خطأ في معالجة يوم: $e');
          }
        }
      }
    }
  }

  Future<void> _saveEventsToCache(List<CalendarEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = events.map((e) => e.toJson()).toList();
    await prefs.setString('cached_events', json.encode(eventsJson));
    debugPrint('💾 تم حفظ ${events.length} حدث في الكاش');
  }

  Future<void> _loadCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_events');

      if (cachedData != null) {
        final List<dynamic> eventsJson = json.decode(cachedData);
        final events =
            eventsJson.map((e) => CalendarEvent.fromJson(e)).toList();

        _organizeEvents(events);

        debugPrint('📦 تم تحميل ${events.length} حدث من الكاش');
      } else {
        _loadDefaultEvents();
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الكاش: $e');
      _loadDefaultEvents();
    }
  }

  void _organizeEvents(List<CalendarEvent> events) {
    _events.clear();

    for (var event in events) {
      final normalizedDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );

      if (_events[normalizedDate] == null) {
        _events[normalizedDate] = [];
      }
      _events[normalizedDate]!.add(event);
    }

    if (mounted) setState(() {});
  }

  void _loadDefaultEvents() {
    debugPrint('📌 استخدام البيانات الأساسية...');

    final currentHijri = HijriCalendar.now();
    final currentYear = currentHijri.hYear;

    _addYearEvents(currentYear);
    _addYearEvents(currentYear + 1);
    _addYearEvents(currentYear - 1);
  }

  void _addYearEvents(int hijriYear) {
    final List<Map<String, dynamic>> islamicEvents = [
      {
        'month': 1,
        'day': 1,
        'title': 'رأس السنة الهجرية',
        'desc': 'بداية العام الهجري $hijriYear',
        'color': Colors.blue.shade300
      },
      {
        'month': 1,
        'day': 10,
        'title': 'يوم عاشوراء',
        'desc': 'اليوم الذي نجى الله فيه موسى عليه السلام',
        'color': Colors.red.shade300
      },
      {
        'month': 3,
        'day': 12,
        'title': 'المولد النبوي الشريف',
        'desc': 'مولد خير الأنام محمد ﷺ',
        'color': Colors.green.shade300
      },
      {
        'month': 7,
        'day': 27,
        'title': 'ليلة الإسراء والمعراج',
        'desc': 'رحلة الإسراء والمعراج المباركة',
        'color': Colors.purple.shade300
      },
      {
        'month': 8,
        'day': 15,
        'title': 'ليلة النصف من شعبان',
        'desc': 'ليلة البراءة المباركة',
        'color': Colors.indigo.shade300
      },
      {
        'month': 9,
        'day': 1,
        'title': 'أول رمضان',
        'desc': 'بداية شهر رمضان المبارك',
        'color': Colors.teal.shade400
      },
      {
        'month': 9,
        'day': 27,
        'title': 'ليلة القدر',
        'desc': 'ليلة خير من ألف شهر',
        'color': Colors.deepPurple.shade600
      },
      {
        'month': 10,
        'day': 1,
        'title': 'عيد الفطر المبارك',
        'desc': 'العيد الصغير - أول أيام شوال',
        'color': Colors.amber.shade400
      },
      {
        'month': 12,
        'day': 9,
        'title': 'يوم عرفة',
        'desc': 'أفضل أيام السنة - وقوف الحجاج بعرفة',
        'color': Colors.orange.shade500
      },
      {
        'month': 12,
        'day': 10,
        'title': 'عيد الأضحى المبارك',
        'desc': 'العيد الكبير - يوم النحر',
        'color': Colors.deepOrange.shade400
      },
    ];

    for (var eventData in islamicEvents) {
      try {
        final hijriDate = HijriCalendar();
        hijriDate.hYear = hijriYear;
        hijriDate.hMonth = eventData['month'] as int;
        hijriDate.hDay = eventData['day'] as int;

        final gregorianDate = hijriDate.hijriToGregorian(
          hijriDate.hYear,
          hijriDate.hMonth,
          hijriDate.hDay,
        );

        final normalizedDate = DateTime(
          gregorianDate.year,
          gregorianDate.month,
          gregorianDate.day,
        );

        if (_events[normalizedDate] == null) {
          _events[normalizedDate] = [];
        }

        _events[normalizedDate]!.add(CalendarEvent(
          title: eventData['title'] as String,
          description: eventData['desc'] as String,
          date: normalizedDate,
          color: eventData['color'] as Color,
          hijriDate: '${hijriDate.hDay}-${hijriDate.hMonth}-${hijriDate.hYear}',
        ));
      } catch (e) {
        debugPrint('❌ خطأ في إضافة حدث: ${eventData['title']} - $e');
      }
    }

    if (mounted) setState(() {});
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  static const Map<int, String> hijriMonthsArabic = {
    1: 'مُحَرَّم',
    2: 'صَفَر',
    3: 'رَبِيع الأَوَّل',
    4: 'رَبِيع الآخِر',
    5: 'جُمَادَى الأُولَى',
    6: 'جُمَادَى الآخِرَة',
    7: 'رَجَب',
    8: 'شَعْبَان',
    9: 'رَمَضَان',
    10: 'شَوَّال',
    11: 'ذُو القَعْدَة',
    12: 'ذُو الحِجَّة',
  };

  static const Map<int, String> arabicDays = {
    1: 'الاثنين',
    2: 'الثلاثاء',
    3: 'الأربعاء',
    4: 'الخميس',
    5: 'الجمعة',
    6: 'السبت',
    7: 'الأحد',
  };

  static const Map<int, String> shortArabicDays = {
    DateTime.monday: 'اثنين',
    DateTime.tuesday: 'ثلاثاء',
    DateTime.wednesday: 'أربعاء',
    DateTime.thursday: 'خميس',
    DateTime.friday: 'جمعة',
    DateTime.saturday: 'سبت',
    DateTime.sunday: 'أحد',
  };

  String _getHijriDateString(DateTime gregorianDate) {
    try {
      final hijri = HijriCalendar.fromDate(gregorianDate);
      final dayArabic = _toArabicNumbers(hijri.hDay.toString());
      final monthName =
          hijriMonthsArabic[hijri.hMonth] ?? hijri.getLongMonthName();
      final yearArabic = _toArabicNumbers(hijri.hYear.toString());

      return '$dayArabic $monthName $yearArabic هـ';
    } catch (e) {
      debugPrint('خطأ في تحويل التاريخ: $e');
      return '';
    }
  }

  // ignore: unused_element
  String _getGregorianDateArabic(DateTime date) {
    try {
      const monthsArabic = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر'
      ];

      final dayName =
          arabicDays[date.weekday] ?? DateFormat('EEEE', 'ar').format(date);
      final day = _toArabicNumbers(date.day.toString());
      final month = monthsArabic[date.month - 1];
      final year = _toArabicNumbers(date.year.toString());

      return '$dayName، $day $month $year';
    } catch (e) {
      return _toArabicNumbers(
          DateFormat('EEEE، d MMMM yyyy', 'ar').format(date));
    }
  }

  String _getShortHijriDay(DateTime gregorianDate) {
    try {
      final hijri = HijriCalendar.fromDate(gregorianDate);
      return _toArabicNumbers(hijri.hDay.toString());
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final daysOfWeekHeight = (24 * textScale).clamp(24.0, 34.0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'التقويم الهجري',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : () async {
                    await _fetchEventsFromAPI();
                  },
            tooltip: 'تحديث التقويم',
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'شهر',
                CalendarFormat.twoWeeks: 'أسبوعان',
                CalendarFormat.week: 'أسبوع',
              },
              locale: 'ar',
              daysOfWeekHeight: daysOfWeekHeight,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: .5),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                defaultTextStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                outsideDaysVisible: false,
                markersMaxCount: 3,
                markerDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                markersAlignment: Alignment.bottomCenter,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: true,
                titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                formatButtonDecoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: primaryColor),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
                weekendStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  final label = shortArabicDays[day.weekday] ?? '';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  final events = _getEventsForDay(day);
                  final hijriDay = _getShortHijriDay(day);

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: events.isNotEmpty
                          ? events.first.color.withValues(alpha: .2)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            _toArabicNumbers(day.day.toString()),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (hijriDay.isNotEmpty)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Text(
                              hijriDay,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        if (events.isNotEmpty)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: events.first.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      _toArabicNumbers(DateFormat('EEEE، d MMMM yyyy', 'ar')
                          .format(_selectedDay!)),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getHijriDateString(_selectedDay!),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _buildEventsList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مناسبات إسلامية في هذا اليوم',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: event.color, width: 2),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  event.color.withValues(alpha: .1),
                  event.color.withValues(alpha: .05),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: event.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              title: Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
