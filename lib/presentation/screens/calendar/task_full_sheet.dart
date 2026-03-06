import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/event_model.dart';
import '../../../logic/event_provider.dart';
import '../../../logic/category_provider.dart';
import '../../../logic/auth_provider.dart';

class TaskFullSheet extends ConsumerStatefulWidget {
  final EventModel? event;
  final DateTime? initialDate;

  const TaskFullSheet({super.key, this.event, this.initialDate});

  @override
  ConsumerState<TaskFullSheet> createState() => _TaskFullSheetState();
}

class _TaskFullSheetState extends ConsumerState<TaskFullSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _priority = 'medium';
  String? _selectedCategoryId;
  bool _remindMe = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? "");
    _descController = TextEditingController(
      text: widget.event?.description ?? "",
    );
    _selectedDate =
        widget.event?.startTime ?? widget.initialDate ?? DateTime.now();
    _startTime = widget.event?.startTime != null
        ? TimeOfDay.fromDateTime(widget.event!.startTime!)
        : TimeOfDay.now();
    _endTime = widget.event?.endTime != null
        ? TimeOfDay.fromDateTime(widget.event!.endTime!)
        : TimeOfDay(
            hour: (TimeOfDay.now().hour + 1) % 24,
            minute: TimeOfDay.now().minute,
          );
    _selectedCategoryId = widget.event?.categoryId;

    final existingPriority = widget.event?.priority;
    if (existingPriority != null) {
      _priority = existingPriority == 1
          ? 'low'
          : (existingPriority == 3 ? 'high' : 'medium');
    }
    _remindMe = widget.event?.reminderMinutes != null;
  }

  int _priorityToInt(String p) {
    switch (p) {
      case 'low':
        return 1;
      case 'high':
        return 3;
      default:
        return 2;
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) return;
    final auth = ref.read(authProvider);

    final start = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    ).toUtc();
    final end = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    ).toUtc();

    final eventData = EventModel(
      id: widget.event?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      startTime: start,
      endTime: end,
      isCompleted: widget.event?.isCompleted ?? false,
      categoryId: _selectedCategoryId,
      userId: auth.user?.id ?? 'me',
      updatedAt: DateTime.now().toUtc(),
      priority: _priorityToInt(_priority),
      reminderMinutes: _remindMe ? 15 : null,
    );

    if (widget.event == null) {
      ref.read(eventProvider.notifier).addEvent(eventData);
    } else {
      ref.read(eventProvider.notifier).updateEventFull(eventData);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider).categories;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                width: 40,
                child: Divider(thickness: 4, color: AppColors.surfaceLight),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Mission Details",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildField("Title", _titleController, false),
            const SizedBox(height: 16),
            _buildField("Description", _descController, true),
            const SizedBox(height: 20),
            _buildDateTimePickers(),
            const SizedBox(height: 20),
            _buildPrioritySelector(),
            const SizedBox(height: 20),
            _buildCategorySelector(categories),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Remind me",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                "15 minutes before",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              value: _remindMe,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              onChanged: (v) => setState(() => _remindMe = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _save,
                child: const Text(
                  "Accept Mission",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String hint,
    TextEditingController controller,
    bool multiLine,
  ) {
    return TextField(
      controller: controller,
      maxLines: multiLine ? 3 : 1,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildDateTimePickers() {
    return Column(
      children: [
        _buildDateTile(
          label: "Date",
          value: DateFormat('EEEE, d MMMM').format(_selectedDate!),
          icon: Icons.calendar_today,
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _selectedDate!,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (d != null) setState(() => _selectedDate = d);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTimeTile(
              label: "Start",
              value: _startTime!.format(context),
              icon: Icons.access_time,
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _startTime!,
                );
                if (t != null) setState(() => _startTime = t);
              },
            ),
            const SizedBox(width: 12),
            _buildTimeTile(
              label: "End",
              value: _endTime!.format(context),
              icon: Icons.access_time_filled,
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _endTime!,
                );
                if (t != null) setState(() => _endTime = t);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final priorities = ['low', 'medium', 'high'];
    return Row(
      children: priorities.map((p) {
        final isSelected = _priority == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priority = p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (p == 'high'
                          ? AppColors.error
                          : (p == 'low' ? Colors.green : AppColors.primary))
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.surfaceLight,
                ),
              ),
              child: Center(
                child: Text(
                  p.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector(List<dynamic> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Category",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategoryId == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = cat.id),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppColors.surfaceLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
