import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';

/// Bottom sheet for quick entry creation.
///
/// UX target: common add-entry flow under 20 seconds.
/// Uses category chips, optional description, datetime, credits, and author fields.
class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  EntryCategory _selectedCategory = EntryCategory.childcare;
  final _descriptionController = TextEditingController();
  final _creditsController = TextEditingController(text: '1.0');
  DateTime _occurredAt = DateTime.now();
  TimeOfDay _occurredTime = TimeOfDay.now();
  late String _selectedAuthorId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAuthorId = context.read<SettingsProvider>().currentUserId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final ledgerProvider = context.read<LedgerProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Add Care Entry', style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Author selection
          if (ledgerProvider.hasLedger) ...[
            Text('Author', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: settings.participantList.map((p) {
                final isSelected = p.id == _selectedAuthorId;
                return ChoiceChip(
                  selected: isSelected,
                  avatar: CircleAvatar(
                    radius: 12,
                    backgroundColor: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      p.initial,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  label: Text(p.name),
                  onSelected: (_) => setState(() => _selectedAuthorId = p.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Category chips
          Text('Category', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: EntryCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat.label),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Description (optional)
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'What did you do? (optional)',
              helperText: 'Leave blank to use "${_selectedCategory.label}"',
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Credits + Date + Time row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _creditsController,
                  decoration: const InputDecoration(
                    labelText: 'Credits',
                    border: OutlineInputBorder(),
                    suffixText: 'cr',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_occurredAt.month}/${_occurredAt.day}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _occurredTime.format(context),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSubmitting ? 'Adding...' : 'Add Entry'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _occurredAt = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _occurredTime,
    );
    if (picked != null) {
      setState(() => _occurredTime = picked);
    }
  }

  Future<void> _submit() async {
    final credits = double.tryParse(_creditsController.text);
    if (credits == null || credits < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid credits')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final description = _descriptionController.text.trim();
    final occurredAt = DateTime(
      _occurredAt.year,
      _occurredAt.month,
      _occurredAt.day,
      _occurredTime.hour,
      _occurredTime.minute,
    );

    final provider = context.read<LedgerProvider>();
    await provider.addEntry(
      category: _selectedCategory,
      description: description.isNotEmpty ? description : null,
      creditsProposed: credits,
      occurredAt: occurredAt,
      authorId: _selectedAuthorId,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
