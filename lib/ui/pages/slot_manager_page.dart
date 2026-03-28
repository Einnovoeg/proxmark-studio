import 'package:flutter/material.dart';

import '../../models/saved_card.dart';
import '../../state/app_state.dart';
import '../../theme/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

/// Shows the eight-card workspace as a real assignment surface instead of a
/// static mockup so cloning and write preparation can happen from one screen.
class SlotManagerPage extends StatelessWidget {
  const SlotManagerPage({super.key, required this.appState, this.onOpenWrite});

  static const int _slotCount = 8;

  final AppState appState;
  final VoidCallback? onOpenWrite;

  @override
  Widget build(BuildContext context) {
    final selectedCard = appState.selectedWriteCard;
    final filledSlots = List<int>.generate(
      _slotCount,
      (index) => index + 1,
    ).where((slot) => appState.slotCard(slot) != null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Slot Manager',
          subtitle:
              'Assign saved cards, switch active slots, and prep emulation.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _summaryChip(
              context,
              icon: Icons.radio_button_checked_rounded,
              label: 'Active slot',
              value: 'Slot ${appState.activeSlot}',
              color: AppPalette.primary,
            ),
            _summaryChip(
              context,
              icon: Icons.view_module_rounded,
              label: 'Filled slots',
              value: '$filledSlots / $_slotCount',
              color: AppPalette.secondary,
            ),
            _summaryChip(
              context,
              icon: Icons.bookmark_rounded,
              label: 'Selected card',
              value: selectedCard?.label ?? 'None selected',
              color: AppPalette.accent,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width > 1200
                  ? 4
                  : width > 900
                  ? 3
                  : width > 640
                  ? 2
                  : 1;
              return GridView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: width > 640 ? 1.0 : 1.16,
                ),
                itemCount: _slotCount,
                itemBuilder: (context, index) {
                  final slotNumber = index + 1;
                  final card = appState.slotCard(slotNumber);
                  return _SlotTile(
                    slotNumber: slotNumber,
                    card: card,
                    isActive: slotNumber == appState.activeSlot,
                    selectedCard: selectedCard,
                    onActivate: () => appState.activateSlot(slotNumber),
                    onAssignSelected: selectedCard == null
                        ? null
                        : () => appState.assignSavedCardToSlot(
                            selectedCard.id,
                            slotNumber,
                          ),
                    onClear: card == null
                        ? null
                        : () => appState.clearSlot(slotNumber),
                    onWrite: card == null || onOpenWrite == null
                        ? null
                        : () {
                            appState.selectWriteCard(card.id);
                            onOpenWrite!();
                          },
                    onPrepareWrite: onOpenWrite,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label • ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slotNumber,
    required this.card,
    required this.isActive,
    required this.selectedCard,
    required this.onActivate,
    required this.onAssignSelected,
    required this.onClear,
    required this.onWrite,
    required this.onPrepareWrite,
  });

  final int slotNumber;
  final SavedCard? card;
  final bool isActive;
  final SavedCard? selectedCard;
  final VoidCallback onActivate;
  final VoidCallback? onAssignSelected;
  final VoidCallback? onClear;
  final VoidCallback? onWrite;
  final VoidCallback? onPrepareWrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = card == null;

    return AppCard(
      onTap: onActivate,
      tooltip: isEmpty
          ? 'Activate slot $slotNumber. ${selectedCard == null ? 'Select a saved card first to assign it here.' : 'Then assign ${selectedCard!.label} to this slot.'}'
          : 'Activate slot $slotNumber and prepare ${card!.label} for writing or emulation.',
      borderColor: isActive ? AppPalette.primary.withValues(alpha: 0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Slot $slotNumber', style: theme.textTheme.labelLarge),
              const Spacer(),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            card?.label ?? 'Empty slot',
            style: theme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            card == null
                ? selectedCard == null
                      ? 'Select a saved card from the library, then assign it to this slot.'
                      : 'Ready to assign ${selectedCard!.label} to this slot.'
                : [
                    card!.type ?? 'Saved tag',
                    if (card!.uid?.isNotEmpty ?? false) 'UID ${card!.uid}',
                  ].join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          if (card?.hasWritePlan ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${card!.normalizedWriteCommands.length} write command(s) ready',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppPalette.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tooltip(
                message: 'Make slot $slotNumber the active profile.',
                child: FilledButton.tonalIcon(
                  onPressed: onActivate,
                  icon: const Icon(Icons.radio_button_checked_rounded),
                  label: const Text('Activate'),
                ),
              ),
              if (onAssignSelected != null &&
                  (card == null || card!.id != selectedCard?.id))
                Tooltip(
                  message: card == null
                      ? 'Assign the selected saved card to slot $slotNumber.'
                      : 'Replace the current slot assignment with the selected saved card.',
                  child: OutlinedButton.icon(
                    onPressed: onAssignSelected,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(card == null ? 'Assign' : 'Replace'),
                  ),
                ),
              if (onWrite != null)
                Tooltip(
                  message:
                      'Open the assigned card in the write planner and keep slot $slotNumber selected.',
                  child: FilledButton.icon(
                    onPressed: onWrite,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Write'),
                  ),
                ),
              if (card == null && onPrepareWrite != null)
                Tooltip(
                  message:
                      'Jump to the write planner for the currently selected saved card.',
                  child: OutlinedButton.icon(
                    onPressed: onPrepareWrite,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Prepare'),
                  ),
                ),
              if (onClear != null)
                Tooltip(
                  message:
                      'Remove the current card assignment from slot $slotNumber.',
                  child: IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
