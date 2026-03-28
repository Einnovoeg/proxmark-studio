import 'package:flutter/material.dart';

import '../../models/saved_card.dart';
import '../../state/app_state.dart';
import '../../theme/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

/// Provides a real write-planning workspace backed by the saved-card library.
class WriteCardsPage extends StatefulWidget {
  const WriteCardsPage({super.key, required this.appState});

  final AppState appState;

  @override
  State<WriteCardsPage> createState() => _WriteCardsPageState();
}

class _WriteCardsPageState extends State<WriteCardsPage> {
  final TextEditingController _planController = TextEditingController();
  String? _loadedCardId;
  bool _queueVerification = true;
  bool _assignToNextFreeSlot = true;
  bool _savePlanToLibrary = true;

  @override
  void initState() {
    super.initState();
    _syncSelectedCard();
  }

  @override
  void didUpdateWidget(covariant WriteCardsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedCard();
  }

  @override
  void dispose() {
    _planController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCard = widget.appState.selectedWriteCard;
    final isDark = theme.brightness == Brightness.dark;
    final mutedSurface = isDark
        ? const Color(0xFF15212E)
        : AppPalette.surfaceMuted;
    final outlineColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.7)
        : AppPalette.outline.withValues(alpha: 0.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 980;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Write Cards',
                subtitle:
                    'Select a saved card, edit its PM3 write plan, and send it safely.',
              ),
              const SizedBox(height: 16),
              if (widget.appState.savedCards.isEmpty)
                AppCard(
                  color: mutedSurface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No saved cards available',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Capture a card from Read or import one into Saved Cards before opening the write planner.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isWide
                          ? (constraints.maxWidth - 16) * 0.42
                          : constraints.maxWidth,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Source card',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Tooltip(
                              message:
                                  'Choose which saved card this write plan should target.',
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedCard?.id,
                                decoration: const InputDecoration(
                                  labelText: 'Saved card',
                                  prefixIcon: Icon(Icons.bookmark_rounded),
                                ),
                                items: widget.appState.savedCards
                                    .map(
                                      (card) => DropdownMenuItem(
                                        value: card.id,
                                        child: Text(
                                          card.label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (cardId) {
                                  widget.appState.selectWriteCard(cardId);
                                  _syncSelectedCard(force: true);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _detailRow(
                              context,
                              'Type',
                              selectedCard?.type ?? 'Unknown tag',
                            ),
                            _detailRow(
                              context,
                              'UID',
                              selectedCard?.uid ?? 'Not recorded',
                            ),
                            _detailRow(
                              context,
                              'Source',
                              _sourceLabel(selectedCard),
                            ),
                            _detailRow(
                              context,
                              'Assigned slots',
                              _slotLabel(selectedCard),
                            ),
                            if (selectedCard?.notes?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 12),
                              Text('Notes', style: theme.textTheme.labelLarge),
                              const SizedBox(height: 6),
                              Text(
                                selectedCard!.notes!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              'Execution options',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            _toggle(
                              context,
                              label: 'Queue verification scan',
                              value: _queueVerification,
                              tooltip:
                                  'Append a follow-up HF or LF search after the write plan.',
                              onChanged: (value) =>
                                  setState(() => _queueVerification = value),
                            ),
                            _toggle(
                              context,
                              label: 'Assign to next free slot after run',
                              value: _assignToNextFreeSlot,
                              tooltip:
                                  'Save the selected card into the next open slot after commands are queued.',
                              onChanged: (value) =>
                                  setState(() => _assignToNextFreeSlot = value),
                            ),
                            _toggle(
                              context,
                              label: 'Save plan back to library',
                              value: _savePlanToLibrary,
                              tooltip:
                                  'Store the current write plan with this saved card before running it.',
                              onChanged: (value) =>
                                  setState(() => _savePlanToLibrary = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide
                          ? (constraints.maxWidth - 16) * 0.58
                          : constraints.maxWidth,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  color: AppPalette.accent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Write plan',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                Tooltip(
                                  message:
                                      'Save the current PM3 commands to the selected card.',
                                  child: OutlinedButton.icon(
                                    onPressed: selectedCard == null
                                        ? null
                                        : _savePlan,
                                    icon: const Icon(Icons.save_outlined),
                                    label: const Text('Save plan'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message:
                                      'Queue the write plan in the live PM3 session.',
                                  child: FilledButton.icon(
                                    onPressed: selectedCard == null
                                        ? null
                                        : _runPlan,
                                    icon: const Icon(Icons.flash_on_rounded),
                                    label: const Text('Run write plan'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _planController,
                              minLines: 12,
                              maxLines: 16,
                              decoration: const InputDecoration(
                                hintText:
                                    'Enter one pm3 command per line.\nExample:\nhf mf dump --file sample.bin\nhf mf restore --file sample.bin',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.terminal_rounded),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: outlineColor),
                                color: mutedSurface,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Planner status',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _pill(
                                        selectedCard == null
                                            ? 'No card selected'
                                            : 'Card selected',
                                        selectedCard == null
                                            ? AppPalette.danger
                                            : AppPalette.success,
                                      ),
                                      _pill(
                                        _normalizedCommands.isEmpty
                                            ? 'Commands needed'
                                            : '${_normalizedCommands.length} command(s)',
                                        _normalizedCommands.isEmpty
                                            ? AppPalette.warning
                                            : AppPalette.secondary,
                                      ),
                                      _pill(
                                        widget.appState.isConnected
                                            ? 'Device connected'
                                            : 'Offline',
                                        widget.appState.isConnected
                                            ? AppPalette.success
                                            : AppPalette.warning,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _planHint(selectedCard),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  List<String> get _normalizedCommands => _planController.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  Future<void> _savePlan() async {
    final selectedCard = widget.appState.selectedWriteCard;
    if (selectedCard == null) return;
    await widget.appState.updateWriteCommands(
      selectedCard.id,
      _normalizedCommands,
    );
  }

  Future<void> _runPlan() async {
    final selectedCard = widget.appState.selectedWriteCard;
    if (selectedCard == null) return;

    final persistedCommands = _normalizedCommands;
    if (_savePlanToLibrary) {
      await widget.appState.updateWriteCommands(
        selectedCard.id,
        persistedCommands,
      );
    }

    if (persistedCommands.isEmpty) {
      await widget.appState.runWritePlan(
        cardId: selectedCard.id,
        commands: const [],
      );
      return;
    }

    final commands = [
      ...persistedCommands,
      if (_queueVerification) _verificationCommandFor(selectedCard),
    ].where((command) => command.trim().isNotEmpty).toList(growable: false);

    await widget.appState.runWritePlan(
      cardId: selectedCard.id,
      commands: commands,
    );
    if (_assignToNextFreeSlot && widget.appState.isConnected) {
      await widget.appState.assignSavedCardToNextFreeSlot(selectedCard.id);
    }
  }

  void _syncSelectedCard({bool force = false}) {
    final selectedCard = widget.appState.selectedWriteCard;
    if (!force && _loadedCardId == selectedCard?.id) {
      return;
    }

    _loadedCardId = selectedCard?.id;
    _planController.text =
        selectedCard?.normalizedWriteCommands.join('\n') ?? '';
  }

  String _slotLabel(SavedCard? card) {
    if (card == null) {
      return 'No assignment';
    }

    final slots = widget.appState.slotsForCard(card.id);
    if (slots.isEmpty) {
      return 'Not assigned';
    }
    return slots.map((slot) => 'Slot $slot').join(', ');
  }

  String _sourceLabel(SavedCard? card) {
    return switch (card?.source) {
      SavedCardSource.scan => 'Captured from Read',
      SavedCardSource.manual => 'Created manually',
      SavedCardSource.imported => 'Imported from file',
      null => 'Unknown',
    };
  }

  String _planHint(SavedCard? card) {
    if (card == null) {
      return 'Select a saved card to build or run a write plan.';
    }

    final frequency = (card.type ?? '').toLowerCase().contains('lf')
        ? 'LF'
        : 'HF';
    return 'Use one PM3 command per line. When verification is enabled, the planner appends `${_verificationCommandFor(card)}` to confirm the $frequency target is still readable after the write queue runs.';
  }

  String _verificationCommandFor(SavedCard card) {
    final type = (card.type ?? '').toLowerCase();
    if (type.contains('lf') ||
        type.contains('hid') ||
        type.contains('em410') ||
        type.contains('t55')) {
      return 'lf search';
    }
    return 'hf search';
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: theme.textTheme.labelLarge)),
        ],
      ),
    );
  }

  Widget _toggle(
    BuildContext context, {
    required String label,
    required bool value,
    required String tooltip,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Switch(value: value, onChanged: onChanged),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
