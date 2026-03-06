import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/event_model.dart';
import '../../../logic/event_provider.dart';
import '../../../logic/auth_provider.dart';
import 'task_full_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  Map<DateTime, List<EventModel>> _groupEventsByDay(List<EventModel> events) {
    final grouped = <DateTime, List<EventModel>>{};
    for (final event in events) {
      final start = event.startTime;
      if (start == null) continue;
      final key = _dateOnly(start);
      grouped.putIfAbsent(key, () => <EventModel>[]).add(event);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? "Explorer";
    final eventsByDay = _groupEventsByDay(eventState.events);
    final selectedKey = _dateOnly(_selectedDay ?? DateTime.now());
    final dailyEvents = List<EventModel>.from(eventsByDay[selectedKey] ?? const []);

    dailyEvents.sort(
      (a, b) => (a.startTime ?? DateTime.now()).compareTo(
        b.startTime ?? DateTime.now(),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(userName),

            _buildCalendarCard(eventsByDay),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Timeline",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(child: _buildTimelineList(dailyEvents)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        backgroundColor: AppColors.primary,
        elevation: 4,
        onPressed: () => _showTaskSheet(context),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, $name!",
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
          Text(
            DateFormat('MMMM dd, yyyy').format(_selectedDay ?? DateTime.now()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(Map<DateTime, List<EventModel>> eventsByDay) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerVisible: true,
        eventLoader: (day) {
          return eventsByDay[_dateOnly(day)] ?? const [];
        },
        availableCalendarFormats: const {
          CalendarFormat.month: 'Month',
          CalendarFormat.week: 'Week',
        },
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          formatButtonTextStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
          ),
          formatButtonDecoration: BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: AppColors.primary)),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
      ),
    );
  }

  Widget _buildTimelineList(List<EventModel> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          "No missions for this day",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeftTimeline(events[index], index == events.length - 1),
            Expanded(
              child: GestureDetector(
                onDoubleTap: () => _showTaskSheet(context, event: events[index]),
                child: _buildTimelineCard(events[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeftTimeline(EventModel event, bool isLast) {
    final timeStr = DateFormat(
      'HH:mm',
    ).format(event.startTime ?? DateTime.now());
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : AppColors.surfaceLight,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 10,
                  width: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(EventModel event) {
    final color = _getPriorityColor(event.priority);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: event.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (event.description?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      event.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                icon: Icon(
                  event.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: event.isCompleted
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                  size: 24,
                ),
                onPressed: () =>
                    ref.read(eventProvider.notifier).toggleComplete(event),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  color: AppColors.error,
                  size: 24,
                ),
                onPressed: () =>
                    ref.read(eventProvider.notifier).deleteEvent(event.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(dynamic p) {
    final priority = p.toString().toLowerCase();
    if (priority == 'high' || priority == '3') return AppColors.error;
    if (priority == 'low' || priority == '1') return Colors.green;
    return AppColors.primary;
  }

  void _showTaskSheet(BuildContext context, {EventModel? event}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TaskFullSheet(event: event, initialDate: _selectedDay),
    );
  }
}
