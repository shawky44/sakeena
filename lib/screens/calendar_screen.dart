// calendar_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarEvent {
  final String title;
  final String description;
  final DateTime date;
  final Color color;
  final EventType type;

  const CalendarEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.color,
    required this.type,
  });
}

enum EventType { islamicFestival, specialDay, gregorianHoliday, personal }

class CalendarConfig {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color highlightColor;
  final bool showIslamicDates;
  final bool showGregorianDates;

  const CalendarConfig({
    this.primaryColor = const Color(0xFF6B8F7F),
    this.secondaryColor = const Color.fromARGB(198, 133, 151, 143),
    this.backgroundColor = const Color(0xFFD9D9D9),
    this.textColor = Colors.black,
    this.highlightColor = const Color.fromARGB(255, 58, 56, 40),
    this.showIslamicDates = true,
    this.showGregorianDates = true,
  });

  CalendarConfig copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? textColor,
    Color? highlightColor,
    bool? showIslamicDates,
    bool? showGregorianDates,
  }) {
    return CalendarConfig(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      highlightColor: highlightColor ?? this.highlightColor,
      showIslamicDates: showIslamicDates ?? this.showIslamicDates,
      showGregorianDates: showGregorianDates ?? this.showGregorianDates,
    );
  }
}

class IslamicDateConverter {
  // Arabic numbers (0-9)
  static const Map<int, String> arabicNumbers = {
    0: '٠',
    1: '١',
    2: '٢',
    3: '٣',
    4: '٤',
    5: '٥',
    6: '٦',
    7: '٧',
    8: '٨',
    9: '٩',
  };

  // Islamic months in Arabic
  static const Map<int, String> islamicMonthsArabic = {
    1: 'مُحَرَّم',
    2: 'صَفَر',
    3: 'رَبِيعُ ٱلْأَوَّل',
    4: 'رَبِيعُ ٱلْآخِر',
    5: 'جُمَادَىٰ ٱلْأُولَىٰ',
    6: 'جُمَادَىٰ ٱلْآخِرَة',
    7: 'رَجَب',
    8: 'شَعْبَان',
    9: 'رَمَضَان',
    10: 'شَوَّال',
    11: 'ذُو ٱلْقَعْدَة',
    12: 'ذُو ٱلْحِجَّة',
  };

  // Convert number to Arabic numerals
  static String toArabicNumbers(int number) {
    return number.toString().split('').map((digit) {
      return arabicNumbers[int.parse(digit)] ?? digit;
    }).join();
  }

  // Accurate Hijri to Gregorian conversion
  static Map<String, int> gregorianToHijri(DateTime gregorianDate) {
    // Base reference: January 1, 2000 = 24 Ramadan 1420
    final baseGregorian = DateTime(2000, 1, 1);
    final baseHijriYear = 1420;
    final baseHijriMonth = 9; // Ramadan
    final baseHijriDay = 24;

    // Days difference
    final daysDiff = gregorianDate.difference(baseGregorian).inDays;

    // Convert to Hijri days
    // 1 Hijri year = 354.36707 days on average
    final totalHijriDays =
        (baseHijriYear * 354.36707 +
        _hijriMonthsToDays(baseHijriMonth, baseHijriDay) +
        daysDiff);

    // Calculate year
    int hijriYear = (totalHijriDays / 354.36707).floor();

    // Calculate remaining days in the year
    double remainingDays = totalHijriDays - (hijriYear * 354.36707);

    // Month lengths (alternating 30 and 29)
    final monthLengths = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];

    int hijriMonth = 1;
    int hijriDay = 1;

    for (int i = 0; i < 12; i++) {
      if (remainingDays <= monthLengths[i]) {
        hijriMonth = i + 1;
        hijriDay = remainingDays.round();
        if (hijriDay < 1) hijriDay = 1;
        if (hijriDay > monthLengths[i]) hijriDay = monthLengths[i];
        break;
      }
      remainingDays -= monthLengths[i];
    }

    return {'year': hijriYear, 'month': hijriMonth, 'day': hijriDay};
  }

  static double _hijriMonthsToDays(int month, int day) {
    final monthLengths = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];
    double days = day.toDouble();
    for (int i = 0; i < month - 1; i++) {
      days += monthLengths[i];
    }
    return days;
  }

  // Convert Hijri to Gregorian - Simple and reliable method
  static DateTime hijriToGregorian(
    int hijriYear,
    int hijriMonth,
    int hijriDay,
  ) {
    try {
      // Base reference: 1 Muharram 1446 = July 7, 2024
      final baseDate = DateTime(2024, 7, 7);
      final baseHijriYear = 1446;

      // Calculate year difference
      final yearDiff = hijriYear - baseHijriYear;

      // Days from years (each Hijri year ≈ 354.36707 days)
      double daysFromYears = yearDiff * 354.36707;

      // Days from months in current year
      final monthLengths = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];
      double daysFromMonths = 0;
      for (int i = 0; i < hijriMonth - 1; i++) {
        daysFromMonths += monthLengths[i];
      }

      // Total days
      double totalDays = daysFromYears + daysFromMonths + hijriDay - 1;

      // Add to base date
      return baseDate.add(Duration(days: totalDays.round()));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in hijriToGregorian: $e');
      }
      return DateTime.now();
    }
  }

  static String getIslamicMonthNameArabic(int month) {
    return islamicMonthsArabic[month] ?? 'غير معروف';
  }

  static String getFullHijriDateArabic(DateTime gregorianDate) {
    final hijri = gregorianToHijri(gregorianDate);
    final dayArabic = toArabicNumbers(hijri['day']!);
    final monthArabic = getIslamicMonthNameArabic(hijri['month']!);
    final yearArabic = toArabicNumbers(hijri['year']!);

    return '$dayArabic $monthArabic $yearArabic هـ';
  }

  static String getHijriDayArabic(DateTime gregorianDate) {
    final hijri = gregorianToHijri(gregorianDate);
    return toArabicNumbers(hijri['day']!);
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late Map<DateTime, List<CalendarEvent>> _events;
  late CalendarConfig _config;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _config = const CalendarConfig();
    _events = {};
    _loadEvents();
  }

  void _loadEvents() {
    // Load events for current year and adjacent years
    final currentYear = _focusedDay.year;
    final events = [
      ..._getAllIslamicEvents(currentYear - 1),
      ..._getAllIslamicEvents(currentYear),
      ..._getAllIslamicEvents(currentYear + 1),
    ];

    _events = {};

    for (final event in events) {
      final day = DateTime(event.date.year, event.date.month, event.date.day);
      _events[day] = [..._events[day] ?? [], event];
    }

    if (kDebugMode) {
      print('📅 Loaded ${events.length} Islamic events');
      for (var event in events.take(5)) {
        print('  ${event.title}: ${event.date}');
      }
    }
  }

  List<CalendarEvent> _getAllIslamicEvents(int year) {
    final List<CalendarEvent> events = [];

    // Major Islamic Festivals with Arabic names
    _addIslamicEvent(
      events,
      year,
      1,
      1,
      "رأس السنة الهجرية",
      "بداية شهر محرّم",
      Colors.blue.shade100,
    );

    _addIslamicEvent(
      events,
      year,
      1,
      10,
      "عاشوراء",
      "يوم عاشوراء",
      Colors.red.shade100,
    );

    _addIslamicEvent(
      events,
      year,
      3,
      12,
      "المولد النبوي",
      "مولد النبي محمد ﷺ",
      Colors.green.shade100,
    );

    _addIslamicEvent(
      events,
      year,
      7,
      27,
      "ليلة الإسراء والمعراج",
      "رحلة الإسراء والمعراج",
      Colors.purple.shade100,
    );

    _addIslamicEvent(
      events,
      year,
      8,
      15,
      "ليلة النصف من شعبان",
      "ليلة البراءة",
      Colors.indigo.shade100,
    );

    _addIslamicEvent(
      events,
      year,
      9,
      1,
      "بداية رمضان",
      "أول أيام شهر رمضان المبارك",
      Colors.teal.shade100,
    );

    _addIslamicEvent(
      events,
      year,
      9,
      27,
      "ليلة القدر",
      "ليلة خير من ألف شهر",
      Colors.deepPurple.shade100,
    );

    _addIslamicEvent(
      events,
      year,
      10,
      1,
      "عيد الفطر",
      "العيد الصغير",
      Colors.orange.shade100,
    );

    _addIslamicEvent(
      events,
      year,
      12,
      9,
      "يوم عرفة",
      "وقوف الحجاج على جبل عرفة",
      Colors.brown.shade100,
    );

    _addIslamicEvent(
      events,
      year,
      12,
      10,
      "عيد الأضحى",
      "العيد الكبير",
      Colors.deepOrange.shade100,
    );

    _addIslamicEvent(
      events,
      year,
      12,
      11,
      "أيام التشريق",
      "أيام الذبح",
      Colors.orange.shade200,
    );

    _addIslamicEvent(
      events,
      year,
      12,
      12,
      "أيام التشريق",
      "أيام الذبح",
      Colors.orange.shade200,
    );

    _addIslamicEvent(
      events,
      year,
      12,
      13,
      "أيام التشريق",
      "أيام الذبح",
      Colors.orange.shade200,
    );

    return events;
  }

  void _addIslamicEvent(
    List<CalendarEvent> events,
    int gregorianYear,
    int hijriMonth,
    int hijriDay,
    String title,
    String desc,
    Color color,
  ) {
    try {
      // Get current Hijri year based on gregorian year
      final currentDate = DateTime(gregorianYear, 6, 1); // Mid year
      final currentHijri = IslamicDateConverter.gregorianToHijri(currentDate);
      final hijriYear = currentHijri['year']!;

      // Convert Hijri date to Gregorian for display
      final gregorianDate = IslamicDateConverter.hijriToGregorian(
        hijriYear,
        hijriMonth,
        hijriDay,
      );

      // Only add if the date falls in the requested Gregorian year (±1 year tolerance)
      if (gregorianDate.year >= gregorianYear - 1 &&
          gregorianDate.year <= gregorianYear + 1) {
        events.add(
          CalendarEvent(
            title: title,
            description: desc,
            date: gregorianDate,
            color: color,
            type: EventType.islamicFestival,
          ),
        );

        if (kDebugMode) {
          print(
            '✅ Islamic Event: $title on $gregorianDate (${hijriDay}/$hijriMonth/$hijriYear هـ)',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding Islamic event $title: $e');
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  String _getHijriDate(DateTime date) {
    return IslamicDateConverter.getFullHijriDateArabic(date);
  }

  Widget _buildEventMarker(CalendarEvent event) {
    Color markerColor = event.color;

    // Make markers more visible based on event type
    if (event.type == EventType.islamicFestival) {
      if (event.title.contains("عيد")) {
        // Eid festivals - brighter colors
        markerColor = Colors.yellow.shade700;
      } else if (event.title.contains("رمضان")) {
        // Ramadan - green
        markerColor = Colors.green.shade700;
      } else {
        // Other Islamic events
        markerColor = Colors.blue.shade700;
      }
    }

    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'لا توجد مناسبات لهذا اليوم',
          style: TextStyle(
            color: _config.textColor.withValues(alpha: .7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          color: event.color.withValues(alpha: .3),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              event.title,
              style: TextStyle(
                color: _config.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textDirection: TextDirection.rtl,
            ),
            subtitle: Text(
              event.description,
              style: TextStyle(
                color: _config.textColor.withValues(alpha: .8),
                fontSize: 14,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      },
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('إعدادات التقويم'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildColorSetting('لون الأساسي', _config.primaryColor, (
                    color,
                  ) {
                    setDialogState(() {
                      _config = _config.copyWith(primaryColor: color);
                    });
                  }),
                  _buildColorSetting('لون الخلفية', _config.backgroundColor, (
                    color,
                  ) {
                    setDialogState(() {
                      _config = _config.copyWith(backgroundColor: color);
                    });
                  }),
                  _buildColorSetting('لون النص', _config.textColor, (color) {
                    setDialogState(() {
                      _config = _config.copyWith(textColor: color);
                    });
                  }),
                  _buildColorSetting('لون التمييز', _config.highlightColor, (
                    color,
                  ) {
                    setDialogState(() {
                      _config = _config.copyWith(highlightColor: color);
                    });
                  }),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('إظهار التواريخ الهجرية'),
                    value: _config.showIslamicDates,
                    onChanged: (value) {
                      setDialogState(() {
                        _config = _config.copyWith(showIslamicDates: value);
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('تطبيق'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorSetting(
    String title,
    Color color,
    Function(Color) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      trailing: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
      onTap: () => _showColorPicker(title, color, onChanged),
    );
  }

  void _showColorPicker(
    String title,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
      Colors.white,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختر $title'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                onColorChanged(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentColor.value == color.value
                        ? Colors.black
                        : Colors.grey,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _config.backgroundColor,
      appBar: AppBar(
        title: const Text('التقويم الهجري والميلادي'),
        backgroundColor: _config.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.only(
              top: 45,
              left: 9,
              right: 9,
              bottom: 20,
            ),
            elevation: 4,
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
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
                _loadEvents();
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: _config.highlightColor.withValues(alpha: .7),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: _config.primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: _config.secondaryColor,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
                markersAlignment: Alignment.bottomLeft,
                markersMaxCount: 3,
              ),
              headerStyle: HeaderStyle(
                titleTextStyle: TextStyle(
                  color: _config.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                formatButtonVisible: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: _config.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: _config.primaryColor,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: _config.primaryColor,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: _config.textColor),
                weekendStyle: TextStyle(color: _config.primaryColor),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final events = _getEventsForDay(day);
                  return Stack(
                    children: [
                      Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: _config.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_config.showIslamicDates)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Text(
                            IslamicDateConverter.getHijriDayArabic(day),
                            style: TextStyle(
                              color: _config.textColor.withValues(alpha: .7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (events.isNotEmpty)
                        Positioned(
                          bottom: 2,
                          left: 2,
                          child: Row(
                            children: events
                                .take(2)
                                .map((event) => _buildEventMarker(event))
                                .toList(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _getHijriDate(_selectedDay!),
                style: TextStyle(
                  color: _config.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
            Expanded(child: _buildEventList()),
          ],
        ],
      ),
    );
  }
}
