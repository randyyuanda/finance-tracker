import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../providers/reminder_provider.dart';
import '../../models/reminder.dart';
import '../../widgets/empty_state.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ReminderProvider>().fetchAll());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Reminder> _filtered(List<Reminder> all, int tab) {
    switch (tab) {
      case 1: return all.where((r) => !r.isCompleted && !r.isOverdue).toList();
      case 2: return all.where((r) => r.isOverdue).toList();
      case 3: return all.where((r) => r.isCompleted).toList();
      default: return all;
    }
  }

  void _showForm({Reminder? reminder}) {
    final titleCtrl = TextEditingController(text: reminder?.title);
    final noteCtrl = TextEditingController(text: reminder?.note);
    DateTime dateTime = reminder?.reminderDate ?? DateTime.now().add(const Duration(hours: 1));
    String type = reminder?.type ?? 'custom';
    String repeatType = reminder?.repeatType ?? 'none';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(reminder == null ? 'New Reminder' : 'Edit Reminder',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
                    validator: (v) => v?.isEmpty == true ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text(formatDateTime(dateTime)),
                    subtitle: const Text('Reminder date & time'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: dateTime,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime(2030),
                      );
                      if (d == null || !ctx.mounted) return;
                      final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(dateTime));
                      if (t == null) return;
                      setLocal(() => dateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    },
                    tileColor: Theme.of(context).inputDecorationTheme.fillColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const [
                            DropdownMenuItem(value: 'custom', child: Text('Custom')),
                            DropdownMenuItem(value: 'bill', child: Text('Bill')),
                            DropdownMenuItem(value: 'goal', child: Text('Goal')),
                            DropdownMenuItem(value: 'recurring', child: Text('Recurring')),
                          ],
                          onChanged: (v) => setLocal(() => type = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: repeatType,
                          decoration: const InputDecoration(labelText: 'Repeat'),
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('None')),
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                            DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                          ],
                          onChanged: (v) => setLocal(() => repeatType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final data = {
                          'title': titleCtrl.text.trim(),
                          'note': noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                          'reminderDate': dateTime.toIso8601String(),
                          'type': type,
                          'repeatType': repeatType,
                        };
                        final provider = context.read<ReminderProvider>();
                        if (reminder == null) {
                          await provider.create(data);
                        } else {
                          await provider.update(reminder.id, data);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(reminder == null ? 'Create Reminder' : 'Update Reminder'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.reminders),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'All (${provider.reminders.length})'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue (${provider.overdueCount})'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: List.generate(4, (tab) {
                final list = _filtered(provider.reminders, tab);
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.notifications_outlined,
                    title: tab == 0 ? 'No reminders yet' : 'Nothing here',
                    subtitle: tab == 0 ? 'Tap + to add your first reminder' : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<ReminderProvider>().fetchAll(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ReminderTile(
                      reminder: list[i],
                      onEdit: () => _showForm(reminder: list[i]),
                      onDelete: () => context.read<ReminderProvider>().delete(list[i].id),
                      onToggle: () => context.read<ReminderProvider>().toggleComplete(list[i].id),
                    ),
                  ),
                );
              }),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _ReminderTile({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  Color get _accentColor => reminder.isCompleted
      ? Colors.green
      : reminder.isOverdue
          ? kExpenseColor
          : kPrimaryColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        leading: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accentColor.withOpacity(0.3)),
            ),
            child: Icon(
              reminder.isCompleted
                  ? Icons.check_circle
                  : reminder.isOverdue
                      ? Icons.error_outline
                      : Icons.notifications_outlined,
              color: _accentColor,
              size: 20,
            ),
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${formatDateTime(reminder.reminderDate)} · ${formatRelative(reminder.reminderDate)}',
              style: TextStyle(fontSize: 12, color: reminder.isOverdue && !reminder.isCompleted ? kExpenseColor : Colors.grey.shade600),
            ),
            Row(
              children: [
                _Chip(reminder.type, _accentColor),
                if (reminder.repeatType != 'none') ...[
                  const SizedBox(width: 4),
                  _Chip(reminder.repeatType, Colors.teal),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'toggle', child: Text('Toggle done')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (v) {
            if (v == 'toggle') onToggle();
            else if (v == 'edit') onEdit();
            else onDelete();
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );
}
