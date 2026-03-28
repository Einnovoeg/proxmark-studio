import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../state/app_state.dart';
import '../../theme/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.appState,
    required this.connected,
    this.portName,
    required this.onOpenConsole,
  });

  final AppState appState;
  final bool connected;
  final String? portName;
  final VoidCallback onOpenConsole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedSurface = isDark
        ? const Color(0xFF15212E)
        : AppPalette.surfaceMuted;
    final recentActivity = appState.recentActivity
        .take(3)
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!appState.coreInfo.isAvailable || !connected)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppCard(
                      color: mutedSurface,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 900;
                          final actionButtons = !appState.coreInfo.isAvailable
                              ? Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    Tooltip(
                                      message:
                                          'Import a local Proxmark3 client build.',
                                      child: FilledButton.icon(
                                        onPressed: appState.importCoreFromFile,
                                        icon: const Icon(
                                          Icons.upload_file_rounded,
                                        ),
                                        label: const Text('Import core'),
                                      ),
                                    ),
                                    Tooltip(
                                      message:
                                          'Download the latest stable official core when a release feed is configured.',
                                      child: OutlinedButton.icon(
                                        onPressed: appState.downloadLatestCore,
                                        icon: const Icon(
                                          Icons.cloud_download_rounded,
                                        ),
                                        label: const Text('Download stable'),
                                      ),
                                    ),
                                  ],
                                )
                              : Tooltip(
                                  message: appState.isConnected
                                      ? 'Disconnect the current PM3 session.'
                                      : 'Connect to the selected Proxmark3 device.',
                                  child: FilledButton.icon(
                                    onPressed: appState.isConnected
                                        ? appState.disconnect
                                        : appState.connect,
                                    icon: Icon(
                                      appState.isConnected
                                          ? Icons.link_off
                                          : Icons.link,
                                    ),
                                    label: Text(
                                      appState.isConnected
                                          ? 'Disconnect'
                                          : 'Connect',
                                    ),
                                  ),
                                );

                          final details = Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appState.coreInfo.isAvailable
                                      ? 'Device not connected'
                                      : 'Core binary not found',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  appState.coreInfo.isAvailable
                                      ? 'Select a Proxmark3 port and click Connect.'
                                      : 'Import a pm3 binary or install an official release build.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppPalette.secondary.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        appState.coreInfo.isAvailable
                                            ? Icons.usb_rounded
                                            : Icons.warning_amber_rounded,
                                        color: appState.coreInfo.isAvailable
                                            ? AppPalette.secondary
                                            : AppPalette.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    details,
                                  ],
                                ),
                                const SizedBox(height: 12),
                                actionButtons,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppPalette.secondary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  appState.coreInfo.isAvailable
                                      ? Icons.usb_rounded
                                      : Icons.warning_amber_rounded,
                                  color: appState.coreInfo.isAvailable
                                      ? AppPalette.secondary
                                      : AppPalette.warning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              details,
                              const SizedBox(width: 12),
                              Flexible(child: actionButtons),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                const SectionHeader(
                  title: 'Device Overview',
                  subtitle: 'Live status, quick actions, and recent activity.',
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 980;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isWide
                              ? (constraints.maxWidth - 16) * 0.6
                              : constraints.maxWidth,
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.usb_rounded,
                                      color: AppPalette.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        connected
                                            ? 'Proxmark3 Ready'
                                            : 'No device connected',
                                        style: theme.textTheme.titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (connected
                                                    ? AppPalette.success
                                                    : AppPalette.danger)
                                                .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        connected ? 'ACTIVE' : 'OFFLINE',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: connected
                                                  ? AppPalette.success
                                                  : AppPalette.danger,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  connected
                                      ? 'Iceman-compatible firmware session is active. Reader tools and command chaining are available.'
                                      : 'Connect your Proxmark3 to begin scanning, library capture, and advanced workflows.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _statChip(
                                      context,
                                      'Core',
                                      appState.coreInfo.versionLabel ??
                                          'unknown',
                                    ),
                                    _statChip(
                                      context,
                                      'Mode',
                                      connected ? 'Session Live' : 'Standby',
                                    ),
                                    _statChip(
                                      context,
                                      'Port',
                                      portName ?? 'Not selected',
                                    ),
                                    _statChip(
                                      context,
                                      'Saved Cards',
                                      appState.savedCards.length.toString(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isWide
                              ? (constraints.maxWidth - 16) * 0.4
                              : constraints.maxWidth,
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Actions',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                _actionTile(
                                  context,
                                  icon: Icons.bolt,
                                  title: 'Download Core',
                                  subtitle:
                                      'Pull latest official bundled core archive.',
                                  color: AppPalette.secondary,
                                  tooltip:
                                      'Check the configured release feed and download the latest stable core.',
                                  onTap: appState.isBusy
                                      ? null
                                      : appState.downloadLatestCore,
                                ),
                                const SizedBox(height: 10),
                                _actionTile(
                                  context,
                                  icon: Icons.hub,
                                  title: 'Open live console',
                                  subtitle:
                                      'Jump to the PM3 terminal and session logs.',
                                  color: AppPalette.primary,
                                  tooltip:
                                      'Open the live console and command history.',
                                  onTap: onOpenConsole,
                                ),
                                const SizedBox(height: 10),
                                _actionTile(
                                  context,
                                  icon: Icons.auto_fix_high,
                                  title: 'Smart scan',
                                  subtitle:
                                      'Identify nearby tags with HF search.',
                                  color: AppPalette.accent,
                                  tooltip: connected
                                      ? 'Run a quick HF search with the connected Proxmark3.'
                                      : 'Connect first, then start a smart HF scan.',
                                  onTap: connected
                                      ? appState.startReadScan
                                      : appState.connect,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Recent Activity',
                  subtitle: 'Latest operations and card interactions.',
                  trailing: Tooltip(
                    message: 'Open the console and full activity log.',
                    child: TextButton.icon(
                      onPressed: onOpenConsole,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('View logs'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: recentActivity.isEmpty
                        ? [
                            _activityRow(
                              context,
                              title: 'No activity yet',
                              subtitle:
                                  'Connect a device or save a card to start building history.',
                              time: 'Now',
                            ),
                          ]
                        : recentActivity
                              .map(
                                (item) => Column(
                                  children: [
                                    _activityRow(
                                      context,
                                      title: item.title,
                                      subtitle: item.detail,
                                      time: _formatTimeAgo(item),
                                    ),
                                    if (recentActivity.last != item)
                                      const Divider(height: 24),
                                  ],
                                ),
                              )
                              .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(ActivityItem item) {
    final delta = DateTime.now().difference(item.timestamp);
    if (delta.inMinutes < 1) return 'Just now';
    if (delta.inHours < 1) return '${delta.inMinutes} min ago';
    if (delta.inDays < 1) return '${delta.inHours} hr ago';
    return '${delta.inDays} day ago';
  }

  Widget _statChip(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedSurface = isDark
        ? const Color(0xFF15212E)
        : AppPalette.surfaceMuted;
    final outlineColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.7)
        : AppPalette.outline.withValues(alpha: 0.6);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mutedSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: outlineColor),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label • ',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              TextSpan(
                text: value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.16),
      onTap: onTap,
      tooltip: tooltip,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: color),
        ],
      ),
    );
  }

  Widget _activityRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String time,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppPalette.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.timeline_rounded, color: AppPalette.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          time,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }
}
