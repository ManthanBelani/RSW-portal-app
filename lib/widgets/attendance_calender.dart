import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../constants/constants.dart';

class CalendarWidget extends StatefulWidget {
  final Map<DateTime, List<AttendanceEvent>>? events;
  final Function(DateTime)? onDaySelected;
  final bool showLegend;
  final bool showSelectedDayEvents;
  final DateTime? initialSelectedDay;
  final CalendarFormat initialFormat;

  const CalendarWidget({
    Key? key,
    this.events,
    this.onDaySelected,
    this.showLegend = true,
    this.showSelectedDayEvents = true,
    this.initialSelectedDay,
    this.initialFormat = CalendarFormat.month,
  }) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<AttendanceEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _calendarFormat = widget.initialFormat;
    _selectedDay = widget.initialSelectedDay ?? DateTime.now();
    _events = widget.events ?? {};

    if (_events.isEmpty) {
      _loadSampleData();
    }
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events != null && widget.events != oldWidget.events) {
      setState(() {
        _events = widget.events!;
      });
    }
  }

  void _loadSampleData() {
    final today = DateTime.now();

    _events[DateTime(today.year, today.month, today.day - 5)] = [
      AttendanceEvent('Incomplete Hours', AttendanceType.incomplete),
    ];

    _events[DateTime(today.year, today.month, today.day - 3)] = [
      AttendanceEvent('Leave Day', AttendanceType.leave),
    ];

    _events[DateTime(today.year, today.month, today.day - 1)] = [
      AttendanceEvent('Incomplete Hours', AttendanceType.incomplete),
    ];

    _events[DateTime(today.year, today.month, today.day - 7)] = [
      AttendanceEvent('Leave Day', AttendanceType.leave),
    ];
  }

  List<AttendanceEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're in a desktop/large screen context
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768; // Large screens (tablets, desktops)

    return Column(
      children: [
        // Calendar
        Container(
          width: isDesktop ? double.infinity : null, // Full width on desktop
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 8.0 : 0.0,
          ),
          child: TableCalendar<AttendanceEvent>(
            availableGestures: AvailableGestures.none,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,

              defaultDecoration: BoxDecoration(),
              todayDecoration: BoxDecoration(),
              selectedDecoration: BoxDecoration(),

              defaultTextStyle: TextStyle(
                color: Colors.transparent,
                fontSize: isDesktop ? 16 : 14,
              ),
              todayTextStyle: TextStyle(
                color: Colors.transparent,
                fontSize: isDesktop ? 16 : 14,
              ),
              selectedTextStyle: TextStyle(
                color: Colors.transparent,
                fontSize: isDesktop ? 16 : 14,
              ),
              weekendTextStyle: TextStyle(
                color: Colors.transparent,
                fontSize: isDesktop ? 16 : 14,
              ),
              holidayTextStyle: TextStyle(
                color: Colors.transparent,
                fontSize: isDesktop ? 16 : 14,
              ),

              // Adjust markers size for desktop
              markersMaxCount: isDesktop ? 5 : 3,
            ),

            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              formatButtonShowsNext: false,
              titleTextStyle: TextStyle(
                fontSize: isDesktop ? 20 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                if (widget.onDaySelected != null) {
                  widget.onDaySelected!(selectedDay);
                }
              }
            },

            // onFormatChanged: (format) {
            //   if (_calendarFormat != format) {
            //     setState(() {
            //       _calendarFormat = format;
            //     });
            //   }
            // },

            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },

            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },

            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return Container(
                  margin: EdgeInsets.all(
                    isDesktop ? 6.0 : 4.0,
                  ), // Larger margin on desktop
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },

              todayBuilder: (context, day, focusedDay) {
                return Container(
                  margin: EdgeInsets.all(
                    isDesktop ? 6.0 : 4.0,
                  ), // Larger margin on desktop
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },

              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  margin: EdgeInsets.all(
                    isDesktop ? 6.0 : 4.0,
                  ), // Larger margin on desktop
                  decoration: BoxDecoration(
                    color: isSameDay(day, DateTime.now())
                        ? Colors.green.shade400
                        : primaryColor1,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },

              outsideBuilder: (context, day, focusedDay) {
                return Container(
                  margin: EdgeInsets.all(
                    isDesktop ? 6.0 : 4.0,
                  ), // Larger margin on desktop
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: isDesktop ? 14 : 12,
                      ),
                    ),
                  ),
                );
              },
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: isDesktop
                        ? -5.0
                        : -3.5, // Adjust position for desktop
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: events.map((event) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          height: isDesktop
                              ? 10
                              : 8, // Larger markers on desktop
                          width: isDesktop ? 10 : 8,
                          decoration: BoxDecoration(
                            color: _getEventColor(event.type),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),

        // Legend (optional) - shown below the calendar
        if (widget.showLegend)
          Container(
            padding: EdgeInsets.all(
              isDesktop ? 20 : 16,
            ), // Larger padding on desktop
            child: isDesktop
                ? Row(
                    // Row layout on desktop
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem(Colors.red, 'Less Attendance'),
                      _buildLegendItem(Colors.orange, 'Leave Day'),
                      _buildLegendItem(Colors.green, 'Today'),
                    ],
                  )
                : Wrap(
                    // Wrap layout on mobile to handle smaller screens better
                    spacing: 16.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildLegendItem(Colors.red, 'Less Attendance'),
                      _buildLegendItem(Colors.orange, 'Leave Day'),
                      _buildLegendItem(Colors.green, 'Today'),
                    ],
                  ),
          ),

        // Selected day events (optional)
        // if (widget.showSelectedDayEvents) ...[
        //   const SizedBox(height: 8.0),
        //   Container(
        //     margin: EdgeInsets.all(
        //       isDesktop ? 20 : 16,
        //     ), // Larger margin on desktop
        //     padding: EdgeInsets.all(
        //       isDesktop ? 20 : 16,
        //     ), // Larger padding on desktop
        //     decoration: BoxDecoration(
        //       color: Colors.grey.shade100,
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text(
        //           'Events for ${_selectedDay?.day}/${_selectedDay?.month}/${_selectedDay?.year}',
        //           style: TextStyle(
        //             fontSize: isDesktop ? 18 : 16, // Larger font on desktop
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //         const SizedBox(height: 12),
        //         _buildEventsList(),
        //       ],
        //     ),
        //   ),
        // ],
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 12,
          width: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay ?? DateTime.now());

    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No events for this day',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return Column(
      children: events.map((event) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getEventColor(event.type), width: 2),
          ),
          child: Row(
            children: [
              Container(
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                  color: _getEventColor(event.type),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getEventColor(AttendanceType type) {
    switch (type) {
      case AttendanceType.incomplete:
        return Colors.red;
      case AttendanceType.leave:
        return Colors.orange;
      case AttendanceType.complete:
        return Colors.green;
    }
  }
}

enum AttendanceType { incomplete, leave, complete }

class AttendanceEvent {
  final String title;
  final AttendanceType type;

  AttendanceEvent(this.title, this.type);
}
