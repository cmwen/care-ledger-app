import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';

/// Bottom sheet for editing an existing care entry.
class EditEntrySheet extends StatefulWidget {
  final CareEntry entry;

  const EditEntrySheet({super.key, required this.entry});

  @override
  State<EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<EditEntrySheet> {
  late EntryCategory _selectedCategory;
  late TextEditingController _descriptionController;
  late TextEditingController _creditsController;
  late DateTime _occurredAt;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.entry.category;
    _descriptionController =
        TextEditingController(text: widget.entry.description);
    _creditsController = TextEditingController(
      text: widget.entry.creditsProposed.toStringAsFixed(1),
    );
    _occurredAt = widget.entry.occurredAt;
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
              Text('Edit Entry', style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Author info
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                settings.participantName(widget.entry.authorId),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(widget.entry.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.entry.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusColor(widget.entry.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What did you do? (optional)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Credits + Date row
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
              const SizedBox(width: 16),
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
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.MMMd().format(_occurredAt),
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

          // Action buttons
          Row(
            children: [
              // Delete button
              if (widget.entry.status != EntryStatus.confirmed)
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              const Spacer(),
              // Save button
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSubmitting ? 'Saving...' : 'Save Changes'),
              ),
            ],
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
    final provider = context.read<LedgerProvider>();
    await provider.updateEntry(
      entryId: widget.entry.id,
      category: _selectedCategory,
      description: description.isNotEmpty ? description : _selectedCategory.label,
      creditsProposed: credits,
      occurredAt: _occurredAt,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<LedgerProvider>();
      await provider.deleteEntry(widget.entry.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Color _statusColor(EntryStatus status) {
    switch (status) {
      case EntryStatus.needsReview:
        return Colors.amber;
      case EntryStatus.pendingCounterpartyReview:
        return Colors.blue;
      case EntryStatus.confirmed:
        return Colors.green;
      case EntryStatus.needsEdit:
        return Colors.orange;
      case EntryStatus.rejected:
        return Colors.red;
    }
  }
}
