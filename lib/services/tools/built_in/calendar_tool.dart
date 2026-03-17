import 'package:device_calendar/device_calendar.dart';
import 'package:qnq/core/services/permission_service.dart';
import 'package:qnq/services/tools/agent_tool.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Built-in tool: allow the agent to read or create events in the user's local calendar.
class CalendarTool extends AgentTool {
  static const String toolId = 'builtin_calendar';
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  CalendarTool() {
    tz.initializeTimeZones();
  }

  @override
  String get id => toolId;

  @override
  String get name => 'calendar_management';

  @override
  String get description =>
      'Use this tool to view or add events to the device calendar. '
      'Supported actions: "list" (shows events for a date range), "create" (adds a new event).';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['list', 'create'],
            'description': 'The action to perform.'
          },
          'startDate': {
            'type': 'string',
            'description': 'Start date (ISO format: YYYY-MM-DD or full timestamp). Required for "list".'
          },
          'endDate': {
            'type': 'string',
            'description': 'End date (ISO format: YYYY-MM-DD or full timestamp). Required for "list".'
          },
          'title': {
            'type': 'string',
            'description': 'Title of the event. Required for "create".'
          },
          'description': {
            'type': 'string',
            'description': 'Description/notes for the event.'
          }
        },
        'required': ['action']
      };

  @override
  String get category => 'info';

  @override
  String get iconName => 'event';

  @override
  List<String> get requiredPermissions => ['calendar'];

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final action = arguments['action'] as String;
    final permissionService = PermissionService();

    if (!await permissionService.requestCalendar()) {
      return 'Error: Calendar permission denied.';
    }

    if (action == 'list') {
      final start = DateTime.tryParse(arguments['startDate'] ?? '');
      final end = DateTime.tryParse(arguments['endDate'] ?? '');

      if (start == null || end == null) {
        return 'Error: Invalid or missing startDate/endDate. Format: YYYY-MM-DD.';
      }

      try {
        final calendars = await _plugin.retrieveCalendars();
        if (calendars.data == null || calendars.data!.isEmpty) {
          return 'No calendars found on the device.';
        }

        // Search across all writable calendars
        String result = 'Events from $start to $end:\n';
        for (var cal in calendars.data!) {
          final eventsRes = await _plugin.retrieveEvents(
            cal.id,
            RetrieveEventsParams(startDate: start, endDate: end),
          );
          if (eventsRes.data != null && eventsRes.data!.isNotEmpty) {
            result += '\nCalendar: ${cal.name}\n';
            for (var event in eventsRes.data!) {
              result += '- ${event.title} (${event.start} to ${event.end})\n';
            }
          }
        }
        return result;
      } catch (e) {
        return 'Error listing events: $e';
      }
    } else if (action == 'create') {
      final title = arguments['title'] as String?;
      final startStr = arguments['startDate'] as String?;
      final endStr = arguments['endDate'] as String?;

      if (title == null || startStr == null || endStr == null) {
        return 'Error: title, startDate, and endDate are required for creating an event.';
      }

      try {
        final calendars = await _plugin.retrieveCalendars();
        if (calendars.data == null || calendars.data!.isEmpty) {
          return 'Error: No local calendars found to save the event to.';
        }

        // Use the first writable calendar
        final writableCalendars = calendars.data!.where((c) => c.isReadOnly == false);
        if (writableCalendars.isEmpty) return 'Error: No writable calendar found.';
        final target = writableCalendars.first;

        final start = DateTime.parse(startStr);
        final end = DateTime.parse(endStr);
        
        final event = Event(target.id);
        event.title = title;
        event.description = arguments['description'];
        event.start = tz.TZDateTime.from(start, tz.local);
        event.end = tz.TZDateTime.from(end, tz.local);

        final saveRes = await _plugin.createOrUpdateEvent(event);
        if (saveRes?.isSuccess == true) {
          return 'Event "$title" created successfully in calendar "${target.name}".';
        } else {
          return 'Error creating event: ${saveRes?.errors.map((e) => e.errorMessage).join(", ")}';
        }
      } catch (e) {
        return 'Error creating event: $e';
      }
    }

    return 'Unknown action: $action';
  }
}
