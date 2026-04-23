import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/goal_provider.dart';
import '../../models/goal.dart';
import '../../widgets/empty_state.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<GoalProvider>().fetchAll());
  }

  void _showForm({Goal? goal}) {
    final nameCtrl = TextEditingController(text: goal?.name);
    final targetCtrl = TextEditingController(text: goal?.targetAmount.toStringAsFixed(0));
    final currentCtrl = TextEditingController(text: goal?.currentAmount.toStringAsFixed(0));
    DateTime? deadline = goal?.deadline;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal == null ? 'New Goal' : 'Edit Goal',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Goal Name'),
                  validator: (v) => v?.isEmpty == true ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: targetCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Target (IDR)'),
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: currentCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Saved (IDR)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined, size: 20),
                  title: Text(deadline != null ? 'Deadline: ${formatDate(deadline!)}' : 'Set deadline (optional)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: deadline ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setLocal(() => deadline = picked);
                  },
                  tileColor: Theme.of(context).inputDecorationTheme.fillColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'targetAmount': double.tryParse(targetCtrl.text) ?? 0,
                        'currentAmount': double.tryParse(currentCtrl.text) ?? 0,
                        if (deadline != null) 'deadline': deadline!.toIso8601String(),
                      };
                      final provider = context.read<GoalProvider>();
                      if (goal == null) {
                        await provider.create(data);
                      } else {
                        await provider.update(goal.id, data);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(goal == null ? 'Create Goal' : 'Update Goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoalProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.goals.isEmpty
              ? EmptyState(
                  icon: Icons.track_changes,
                  title: 'No goals yet',
                  subtitle: 'Set savings goals to track your progress',
                  actionLabel: 'Add Goal',
                  onAction: () => _showForm(),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<GoalProvider>().fetchAll(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.goals.length,
                    itemBuilder: (_, i) => _GoalCard(
                      goal: provider.goals[i],
                      onEdit: () => _showForm(goal: provider.goals[i]),
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete goal?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirmed == true) context.read<GoalProvider>().delete(provider.goals[i].id);
                      },
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({required this.goal, required this.onEdit, required this.onDelete});

  Color get _color {
    try { return Color(int.parse(goal.color.replaceFirst('#', '0xFF'))); } catch (_) { return kPrimaryColor; }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(goal.isCompleted ? Icons.check_circle : Icons.track_changes, color: _color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      if (goal.deadline != null)
                        Text('Deadline: ${formatDate(goal.deadline!)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: _color.withOpacity(0.15),
                color: goal.isCompleted ? Colors.green : _color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatCurrency(goal.currentAmount),
                    style: TextStyle(fontWeight: FontWeight.w700, color: _color)),
                Text('of ${formatCurrency(goal.targetAmount)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
