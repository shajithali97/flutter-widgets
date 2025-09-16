import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() {
  return runApp(CalendarApp());
}

/// The app which hosts the home page which contains the calendar on it.
class CalendarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Calendar Demo',
        theme: ThemeData.light().copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor:
                MaterialStateProperty.all(Color(0xFF7165E3).withOpacity(0.5)),
            thumbVisibility: MaterialStateProperty.all<bool>(true),
          ),
        ),
        home: MyHomePage());
  }
}

/// The home page which hosts the calendar
class MyHomePage extends StatefulWidget {
  /// Creates the home page to display the calendar widget.
  const MyHomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MeetingDataSource _dataSource;
  List<String> _activityLog = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _dataSource = MeetingDataSource(_getDataSource());
    _logActivity("Calendar initialized");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(scrollbars: false), // avoid auto

        child: SfCalendar(
          view: CalendarView.week,
          firstDayOfWeek: 7,
          timeSlotViewSettings: TimeSlotViewSettings(
            timeInterval: const Duration(minutes: 30),
            timeIntervalHeight: 25,
            timeFormat: 'H:mm',
            dayFormat: 'EEE',
          ),
          todayHighlightColor: Colors.purple,
          dataSource: _dataSource,
          onTap: _onCalendarTapped,
          onLongPress: _onCalendarLongPressed,
        ),
      ),
    );
  }

  void _onCalendarTapped(CalendarTapDetails details) {
    final DateTime tappedDate = details.date!;
    final List<dynamic> appointments = details.appointments ?? [];

    if (appointments.isEmpty &&
        details.targetElement == CalendarElement.calendarCell) {
      // Tapped on empty space - add new activity
      _showAddActivityDialog(tappedDate);
      _logActivity("Tapped empty slot at ${_formatDateTime(tappedDate)}");
    } else if (appointments.isNotEmpty) {
      // Tapped on existing appointment
      final Meeting meeting = appointments.first as Meeting;
      _logActivity(
          "Tapped appointment: '${meeting.eventName}' at ${_formatDateTime(tappedDate)}");
      _showActivityDetails(meeting);
    }
  }

  void _onCalendarLongPressed(CalendarLongPressDetails details) {
    final DateTime longPressedDate = details.date!;
    final List<dynamic> appointments = details.appointments ?? [];

    if (appointments.isNotEmpty) {
      // Long pressed on existing appointment - option to delete
      final Meeting meeting = appointments.first as Meeting;
      _logActivity(
          "Long pressed appointment: '${meeting.eventName}' at ${_formatDateTime(longPressedDate)}");
      _showDeleteConfirmation(meeting);
    } else {
      _logActivity(
          "Long pressed empty slot at ${_formatDateTime(longPressedDate)}");
    }
  }

  void _showAddActivityDialog(DateTime dateTime) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Time: ${_formatDateTime(dateTime)}'),
              SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Activity Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  _addNewActivity(dateTime, titleController.text,
                      descriptionController.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addNewActivity(DateTime startTime, String title, String description) {
    final Meeting newMeeting = Meeting(
      title,
      startTime,
      startTime.add(Duration(hours: 1)),
      Colors.blue,
      false,
    );

    _dataSource.appointments!.add(newMeeting);
    _dataSource.notifyListeners(CalendarDataSourceAction.add, [newMeeting]);

    _logActivity("Added activity: '$title' at ${_formatDateTime(startTime)}");
  }

  void _showActivityDetails(Meeting meeting) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(meeting.eventName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start: ${_formatDateTime(meeting.from)}'),
              Text('End: ${_formatDateTime(meeting.to)}'),
              SizedBox(height: 8),
              Text(
                  'Duration: ${meeting.to.difference(meeting.from).inMinutes} minutes'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Meeting meeting) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Activity'),
          content:
              Text('Are you sure you want to delete "${meeting.eventName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteActivity(meeting);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteActivity(Meeting meeting) {
    _dataSource.appointments!.remove(meeting);
    _dataSource.notifyListeners(CalendarDataSourceAction.remove, [meeting]);
    _logActivity(
        "Deleted activity: '${meeting.eventName}' from ${_formatDateTime(meeting.from)}");
  }

  void _logActivity(String activity) {
    setState(() {
      final String timestamp = DateTime.now().toString().substring(11, 19);
      _activityLog.add("[$timestamp] $activity");
    });

    // Auto-scroll to bottom of log
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLog() {
    setState(() {
      _activityLog.clear();
    });
    _logActivity("Activity log cleared");
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  List<Meeting> _getDataSource() {
    final List<Meeting> meetings = <Meeting>[];
    final DateTime today = DateTime.now();
    final DateTime startTime = DateTime(today.year, today.month, today.day, 9);
    final DateTime endTime = startTime.add(const Duration(hours: 2));
    meetings.add(Meeting(
        'Conference', startTime, endTime, const Color(0xFF0F8644), false));
    return meetings;
  }
}

/// An object to set the appointment collection data source to calendar, which
/// used to map the custom appointment data to the calendar appointment, and
/// allows to add, remove or reset the appointment collection.
class MeetingDataSource extends CalendarDataSource {
  /// Creates a meeting data source, which used to set the appointment
  /// collection to the calendar
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return _getMeetingData(index).from;
  }

  @override
  DateTime getEndTime(int index) {
    return _getMeetingData(index).to;
  }

  @override
  String getSubject(int index) {
    return _getMeetingData(index).eventName;
  }

  @override
  Color getColor(int index) {
    return _getMeetingData(index).background;
  }

  @override
  bool isAllDay(int index) {
    return _getMeetingData(index).isAllDay;
  }

  Meeting _getMeetingData(int index) {
    final dynamic meeting = appointments![index];
    late final Meeting meetingData;
    if (meeting is Meeting) {
      meetingData = meeting;
    }

    return meetingData;
  }
}

/// Custom business object class which contains properties to hold the detailed
/// information about the event data which will be rendered in calendar.
class Meeting {
  /// Creates a meeting class with required details.
  Meeting(this.eventName, this.from, this.to, this.background, this.isAllDay);

  /// Event name which is equivalent to subject property of [Appointment].
  String eventName;

  /// From which is equivalent to start time property of [Appointment].
  DateTime from;

  /// To which is equivalent to end time property of [Appointment].
  DateTime to;

  /// Background which is equivalent to color property of [Appointment].
  Color background;

  /// IsAllDay which is equivalent to isAllDay property of [Appointment].
  bool isAllDay;
}
