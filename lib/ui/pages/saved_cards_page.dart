import 'package:flutter/material.dart';

import '../../models/saved_card.dart';
import '../../state/app_state.dart';
import '../../theme/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

class SavedCardsPage extends StatefulWidget {
  const SavedCardsPage({
    super.key,
    required this.appState,
    required this.onOpenWrite,
  });

  final AppState appState;
  final VoidCallback onOpenWrite;

  @override
  State<SavedCardsPage> createState() => _SavedCardsPageState();
}

class _SavedCardsPageState extends State<SavedCardsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredCards = widget.appState.savedCards
        .where((card) {
          final haystack = [
            card.label,
            card.type ?? '',
            card.uid ?? '',
            card.notes ?? '',
          ].join(' ').toLowerCase();
          return haystack.contains(_query.toLowerCase());
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Saved Cards',
          subtitle: 'Your local library of captured and imported tags.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search UID, label, or tag type',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Import saved card metadata from JSON, TXT, or BIN.',
              child: FilledButton.icon(
                onPressed: widget.appState.importSavedCardFromFile,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Import'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredCards.isEmpty
              ? AppCard(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border_rounded,
                          size: 48,
                          color: AppPalette.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _query.isEmpty
                              ? 'No saved cards yet'
                              : 'No saved cards match this filter',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use Read to capture a card or Import to load card metadata.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: filteredCards.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final card = filteredCards[index];
                    final isSelected =
                        widget.appState.selectedWriteCardId == card.id;
                    return _SavedCardTile(
                      card: card,
                      isSelected: isSelected,
                      onSelect: () => widget.appState.selectWriteCard(card.id),
                      onCloneToSlot: () => widget.appState
                          .assignSavedCardToNextFreeSlot(card.id),
                      onWrite: () {
                        widget.appState.selectWriteCard(card.id);
                        widget.onOpenWrite();
                      },
                      onDelete: () => widget.appState.deleteSavedCard(card.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  const _SavedCardTile({
    required this.card,
    required this.isSelected,
    required this.onSelect,
    required this.onCloneToSlot,
    required this.onWrite,
    required this.onDelete,
  });

  final SavedCard card;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onCloneToSlot;
  final VoidCallback onWrite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      tooltip: 'Select this card for slot assignment and write planning.',
      onTap: onSelect,
      borderColor: isSelected
          ? AppPalette.primary.withValues(alpha: 0.35)
          : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPalette.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.credit_card, color: AppPalette.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.label, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  [
                    card.type ?? 'Unknown tag',
                    if (card.uid != null) 'UID ${card.uid}',
                  ].join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                if (card.notes != null && card.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      card.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (card.hasWritePlan)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${card.normalizedWriteCommands.length} write command(s) saved',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppPalette.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tooltip(
                message: 'Assign this card to the next available slot.',
                child: OutlinedButton(
                  onPressed: onCloneToSlot,
                  child: const Text('Slot'),
                ),
              ),
              Tooltip(
                message: 'Open this card in the write planner.',
                child: FilledButton(
                  onPressed: onWrite,
                  child: const Text('Write'),
                ),
              ),
              Tooltip(
                message: 'Remove this card from the local library.',
                child: IconButton(
                  tooltip: 'Remove from library',
                  onPressed: onDelete,
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
