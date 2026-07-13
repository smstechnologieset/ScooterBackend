import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../domain/admin_dashboard.dart';

enum _FleetFilter {
  all,
  online,
  alerts;
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  _FleetFilter _filter = _FleetFilter.all;
  String _query = '';
  String? _selectedScooterId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardValue = ref.watch(adminDashboardProvider);
    final actionState = ref.watch(adminFleetActionControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: dashboardValue.when(
          data: (dashboard) {
            final scooters = _filterScooters(dashboard.scooters);
            final selectedScooter = _selectedScooter(scooters) ??
                _selectedScooter(dashboard.scooters);

            return _DashboardContent(
              dashboard: dashboard,
              scooters: scooters,
              selectedScooter: selectedScooter,
              selectedScooterId: _selectedScooterId,
              searchController: _searchController,
              filter: _filter,
              actionBusy: actionState.isLoading,
              onRefresh: () => ref.invalidate(adminDashboardProvider),
              onQueryChanged: (value) => setState(() => _query = value),
              onClearQuery: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              onFilterChanged: (filter) => setState(() => _filter = filter),
              onSelectScooter: (scooter) =>
                  setState(() => _selectedScooterId = scooter.id),
              onAction: (scooter, action) =>
                  _runAction(dashboard, scooter, action),
            );
          },
          loading: () => const _LoadingState(),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(adminDashboardProvider),
          ),
        ),
      ),
    );
  }

  List<AdminScooter> _filterScooters(List<AdminScooter> scooters) {
    final normalizedQuery = _query.trim().toLowerCase();

    return scooters.where((scooter) {
      final matchesQuery = normalizedQuery.isEmpty ||
          scooter.publicCode.toLowerCase().contains(normalizedQuery) ||
          scooter.deviceId.toLowerCase().contains(normalizedQuery);
      final matchesFilter = switch (_filter) {
        _FleetFilter.all => true,
        _FleetFilter.online => scooter.isOnline,
        _FleetFilter.alerts => scooter.requiresAttention,
      };

      return matchesQuery && matchesFilter;
    }).toList(growable: false);
  }

  AdminScooter? _selectedScooter(List<AdminScooter> scooters) {
    if (scooters.isEmpty) {
      return null;
    }

    if (_selectedScooterId != null) {
      for (final scooter in scooters) {
        if (scooter.id == _selectedScooterId) {
          return scooter;
        }
      }
    }

    return scooters.first;
  }

  Future<void> _runAction(
    AdminDashboard dashboard,
    AdminScooter scooter,
    AdminScooterAction action,
  ) async {
    if (!dashboard.isLive) {
      _showMessage('Live backend connection required for commands.');
      return;
    }

    try {
      await ref
          .read(adminFleetActionControllerProvider.notifier)
          .dispatch(scooter.id, action);
      if (!mounted) {
        return;
      }

      final actionLabel = action == AdminScooterAction.lock ? 'Lock' : 'Unlock';
      _showMessage('$actionLabel command queued for ${scooter.publicCode}.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Command failed: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.surfaceElevated,
        ),
      );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.dashboard,
    required this.scooters,
    required this.selectedScooter,
    required this.selectedScooterId,
    required this.searchController,
    required this.filter,
    required this.actionBusy,
    required this.onRefresh,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onFilterChanged,
    required this.onSelectScooter,
    required this.onAction,
  });

  final AdminDashboard dashboard;
  final List<AdminScooter> scooters;
  final AdminScooter? selectedScooter;
  final String? selectedScooterId;
  final TextEditingController searchController;
  final _FleetFilter filter;
  final bool actionBusy;
  final VoidCallback onRefresh;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<_FleetFilter> onFilterChanged;
  final ValueChanged<AdminScooter> onSelectScooter;
  final void Function(AdminScooter scooter, AdminScooterAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final contentPadding = EdgeInsets.fromLTRB(
          isWide ? 28 : 18,
          20,
          isWide ? 28 : 18,
          28,
        );

        return RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: () async => onRefresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(
                  isLive: dashboard.isLive,
                  onBack: () => context.go('/menu'),
                  onRefresh: onRefresh,
                ),
                const SizedBox(height: 20),
                _MetricGrid(metrics: dashboard.metrics),
                const SizedBox(height: 18),
                _FleetControls(
                  searchController: searchController,
                  filter: filter,
                  isWide: isWide,
                  onQueryChanged: onQueryChanged,
                  onClearQuery: onClearQuery,
                  onFilterChanged: onFilterChanged,
                ),
                const SizedBox(height: 18),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _FleetTable(
                          scooters: scooters,
                          selectedScooterId: selectedScooterId,
                          commandsEnabled: dashboard.isLive,
                          actionBusy: actionBusy,
                          onSelectScooter: onSelectScooter,
                          onAction: onAction,
                        ),
                      ),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: 340,
                        child: Column(
                          children: [
                            _ScooterFocusPanel(
                              scooter: selectedScooter,
                              commandsEnabled: dashboard.isLive,
                              actionBusy: actionBusy,
                              onAction: onAction,
                            ),
                            const SizedBox(height: 18),
                            _EventsPanel(events: dashboard.events),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _ScooterFocusPanel(
                    scooter: selectedScooter,
                    commandsEnabled: dashboard.isLive,
                    actionBusy: actionBusy,
                    onAction: onAction,
                  ),
                  const SizedBox(height: 14),
                  _FleetCardList(
                    scooters: scooters,
                    selectedScooterId: selectedScooterId,
                    commandsEnabled: dashboard.isLive,
                    actionBusy: actionBusy,
                    onSelectScooter: onSelectScooter,
                    onAction: onAction,
                  ),
                  const SizedBox(height: 14),
                  _EventsPanel(events: dashboard.events),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.isLive,
    required this.onBack,
    required this.onRefresh,
  });

  final bool isLive;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: 'Menu',
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fleet operations',
                style: AppTheme.bodyMutedStyle.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        _LiveBadge(isLive: isLive),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Refresh',
          child: IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final color = isLive ? AppTheme.primaryGreen : Colors.amber;
    final label = isLive ? 'Live' : 'Snapshot';

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isLive ? Icons.cloud_done : Icons.storage,
              color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style:
                AppTheme.bodyStrongStyle.copyWith(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final AdminFleetMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData(Icons.electric_bike, 'Fleet', '${metrics.total}', 'Scooters'),
      _MetricData(Icons.wifi_tethering, 'Online', '${metrics.online}',
          '${metrics.offline} offline'),
      _MetricData(Icons.navigation, 'In ride', '${metrics.inRide}',
          '${metrics.locked} locked'),
      _MetricData(Icons.report, 'Alerts', '${metrics.alerts}',
          '${metrics.lowBattery} battery'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 104,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData(this.icon, this.label, this.value, this.caption);

  final IconData icon;
  final String label;
  final String value;
  final String caption;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withAlpha(28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data.label,
                    style: AppTheme.bodyMutedStyle.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  data.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMutedStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetControls extends StatelessWidget {
  const _FleetControls({
    required this.searchController,
    required this.filter,
    required this.isWide,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onFilterChanged,
  });

  final TextEditingController searchController;
  final _FleetFilter filter;
  final bool isWide;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<_FleetFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      onChanged: onQueryChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search fleet',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchController.text.isEmpty
            ? null
            : Tooltip(
                message: 'Clear',
                child: IconButton(
                  onPressed: onClearQuery,
                  icon: const Icon(Icons.close),
                ),
              ),
      ),
    );

    final filters = SegmentedButton<_FleetFilter>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
            value: _FleetFilter.all,
            icon: Icon(Icons.grid_view),
            label: Text('All')),
        ButtonSegment(
            value: _FleetFilter.online,
            icon: Icon(Icons.wifi),
            label: Text('Online')),
        ButtonSegment(
            value: _FleetFilter.alerts,
            icon: Icon(Icons.warning),
            label: Text('Alerts')),
      ],
      selected: {filter},
      onSelectionChanged: (selection) => onFilterChanged(selection.first),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 14),
          filters,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        search,
        const SizedBox(height: 12),
        filters,
      ],
    );
  }
}

class _FleetTable extends StatelessWidget {
  const _FleetTable({
    required this.scooters,
    required this.selectedScooterId,
    required this.commandsEnabled,
    required this.actionBusy,
    required this.onSelectScooter,
    required this.onAction,
  });

  final List<AdminScooter> scooters;
  final String? selectedScooterId;
  final bool commandsEnabled;
  final bool actionBusy;
  final ValueChanged<AdminScooter> onSelectScooter;
  final void Function(AdminScooter scooter, AdminScooterAction action) onAction;

  @override
  Widget build(BuildContext context) {
    if (scooters.isEmpty) {
      return const _EmptyState();
    }

    return Container(
      decoration: _panelDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 760),
          child: DataTable(
            columnSpacing: 22,
            horizontalMargin: 16,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 68,
            columns: const [
              DataColumn(label: Text('Scooter')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Battery')),
              DataColumn(label: Text('Ride')),
              DataColumn(label: Text('Last seen')),
              DataColumn(label: Text('Actions')),
            ],
            rows: scooters.map((scooter) {
              return DataRow(
                selected: scooter.id == selectedScooterId,
                onSelectChanged: (_) => onSelectScooter(scooter),
                cells: [
                  DataCell(_ScooterIdentity(scooter: scooter)),
                  DataCell(_StatusBadge(
                    label: _statusLabel(scooter.status),
                    icon: scooter.isOnline ? Icons.wifi : Icons.wifi_off,
                    color: _statusColor(scooter.status),
                  )),
                  DataCell(_BatteryInline(scooter: scooter)),
                  DataCell(Text(_rideLabel(scooter.rideState))),
                  DataCell(Text(_timeAgo(scooter.lastHeartbeatAt))),
                  DataCell(_ActionButtons(
                    scooter: scooter,
                    enabled: commandsEnabled && !actionBusy,
                    onAction: (action) => onAction(scooter, action),
                  )),
                ],
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _FleetCardList extends StatelessWidget {
  const _FleetCardList({
    required this.scooters,
    required this.selectedScooterId,
    required this.commandsEnabled,
    required this.actionBusy,
    required this.onSelectScooter,
    required this.onAction,
  });

  final List<AdminScooter> scooters;
  final String? selectedScooterId;
  final bool commandsEnabled;
  final bool actionBusy;
  final ValueChanged<AdminScooter> onSelectScooter;
  final void Function(AdminScooter scooter, AdminScooterAction action) onAction;

  @override
  Widget build(BuildContext context) {
    if (scooters.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: scooters.map((scooter) {
        final selected = scooter.id == selectedScooterId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onSelectScooter(scooter),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _panelDecoration(
                borderColor: selected
                    ? AppTheme.primaryGreen.withAlpha(150)
                    : AppTheme.cardBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _ScooterIdentity(scooter: scooter)),
                      _StatusBadge(
                        label: _statusLabel(scooter.status),
                        icon: scooter.isOnline ? Icons.wifi : Icons.wifi_off,
                        color: _statusColor(scooter.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: _TinyStat(
                              label: 'Battery', value: scooter.batteryLabel)),
                      Expanded(
                          child: _TinyStat(
                              label: 'Ride',
                              value: _rideLabel(scooter.rideState))),
                      Expanded(
                          child: _TinyStat(
                              label: 'Seen',
                              value: _timeAgo(scooter.lastHeartbeatAt))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ActionButtons(
                    scooter: scooter,
                    enabled: commandsEnabled && !actionBusy,
                    onAction: (action) => onAction(scooter, action),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ScooterFocusPanel extends StatelessWidget {
  const _ScooterFocusPanel({
    required this.scooter,
    required this.commandsEnabled,
    required this.actionBusy,
    required this.onAction,
  });

  final AdminScooter? scooter;
  final bool commandsEnabled;
  final bool actionBusy;
  final void Function(AdminScooter scooter, AdminScooterAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final selected = scooter;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: selected == null
          ? const _EmptyState(
              title: 'No scooters', subtitle: 'Fleet list is empty.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withAlpha(28),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.electric_bike,
                          color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _ScooterIdentity(scooter: selected)),
                  ],
                ),
                const SizedBox(height: 16),
                _StatusBadge(
                  label: _statusLabel(selected.status),
                  icon: selected.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _statusColor(selected.status),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                    icon: Icons.lock,
                    label: 'Lock',
                    value: _lockLabel(selected.lockState)),
                _DetailRow(
                    icon: Icons.route,
                    label: 'Ride',
                    value: _rideLabel(selected.rideState)),
                _DetailRow(
                    icon: Icons.battery_6_bar,
                    label: 'Battery',
                    value: selected.batteryLabel),
                _DetailRow(
                    icon: Icons.network_cell,
                    label: 'Signal',
                    value: selected.signalLabel),
                _DetailRow(
                    icon: Icons.place,
                    label: 'Location',
                    value: _locationLabel(selected)),
                _DetailRow(
                    icon: Icons.schedule,
                    label: 'Heartbeat',
                    value: _timeAgo(selected.lastHeartbeatAt)),
                const SizedBox(height: 12),
                _ActionButtons(
                  scooter: selected,
                  enabled: commandsEnabled && !actionBusy,
                  onAction: (action) => onAction(selected, action),
                ),
              ],
            ),
    );
  }
}

class _EventsPanel extends StatelessWidget {
  const _EventsPanel({required this.events});

  final List<AdminFleetEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent events',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          ...events.map((event) => _EventTile(event: event)),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final AdminFleetEvent event;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.severity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_eventIcon(event.severity), color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyStrongStyle.copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      _timeAgo(event.createdAt),
                      style: AppTheme.bodyMutedStyle.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  event.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMutedStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScooterIdentity extends StatelessWidget {
  const _ScooterIdentity({required this.scooter});

  final AdminScooter scooter;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.electric_bike, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                scooter.publicCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyStrongStyle,
              ),
              Text(
                scooter.deviceId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyMutedStyle.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BatteryInline extends StatelessWidget {
  const _BatteryInline({required this.scooter});

  final AdminScooter scooter;

  @override
  Widget build(BuildContext context) {
    final color = _batteryColor(scooter.batteryPercent);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.battery_6_bar, color: color, size: 18),
        const SizedBox(width: 6),
        Text(scooter.batteryLabel),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.scooter,
    required this.enabled,
    required this.onAction,
  });

  final AdminScooter scooter;
  final bool enabled;
  final ValueChanged<AdminScooterAction> onAction;

  @override
  Widget build(BuildContext context) {
    final canLock = enabled && scooter.lockState != AdminLockState.locked;
    final canUnlock = enabled && scooter.lockState != AdminLockState.unlocked;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Lock',
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: canLock ? () => onAction(AdminScooterAction.lock) : null,
            icon: const Icon(Icons.lock),
          ),
        ),
        Tooltip(
          message: 'Unlock',
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed:
                canUnlock ? () => onAction(AdminScooterAction.unlock) : null,
            icon: const Icon(Icons.lock_open),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style:
                AppTheme.bodyStrongStyle.copyWith(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyMutedStyle.copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyStrongStyle.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppTheme.bodyMutedStyle.copyWith(fontSize: 12)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyStrongStyle.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.title = 'No matches',
    this.subtitle = 'Try another search or filter.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.manage_search, color: AppTheme.textMuted, size: 28),
          const SizedBox(height: 10),
          Text(title, style: AppTheme.bodyStrongStyle),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMutedStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 36),
            const SizedBox(height: 12),
            Text('Unable to load dashboard', style: AppTheme.bodyStrongStyle),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMutedStyle,
            ),
            const SizedBox(height: 16),
            IconButton(
              tooltip: 'Retry',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration({Color? borderColor}) {
  return BoxDecoration(
    color: AppTheme.surfaceElevated,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor ?? AppTheme.cardBorder),
  );
}

String _statusLabel(AdminConnectionStatus status) {
  return status == AdminConnectionStatus.online ? 'Online' : 'Offline';
}

Color _statusColor(AdminConnectionStatus status) {
  return status == AdminConnectionStatus.online
      ? AppTheme.primaryGreen
      : AppTheme.danger;
}

String _lockLabel(AdminLockState state) {
  return switch (state) {
    AdminLockState.locked => 'Locked',
    AdminLockState.unlocked => 'Unlocked',
    AdminLockState.unknown => 'Unknown',
  };
}

String _rideLabel(AdminRideState state) {
  return switch (state) {
    AdminRideState.idle => 'Idle',
    AdminRideState.reserved => 'Reserved',
    AdminRideState.inRide => 'In ride',
    AdminRideState.maintenance => 'Maintenance',
    AdminRideState.unknown => 'Unknown',
  };
}

Color _batteryColor(int? batteryPercent) {
  if (batteryPercent == null) {
    return AppTheme.textMuted;
  }

  if (batteryPercent <= 20) {
    return AppTheme.danger;
  }

  if (batteryPercent <= 40) {
    return Colors.amber;
  }

  return AppTheme.primaryGreen;
}

IconData _eventIcon(AdminEventSeverity severity) {
  return switch (severity) {
    AdminEventSeverity.critical => Icons.report,
    AdminEventSeverity.warning => Icons.warning,
    AdminEventSeverity.info => Icons.info,
  };
}

Color _eventColor(AdminEventSeverity severity) {
  return switch (severity) {
    AdminEventSeverity.critical => AppTheme.danger,
    AdminEventSeverity.warning => Colors.amber,
    AdminEventSeverity.info => AppTheme.primaryGreen,
  };
}

String _locationLabel(AdminScooter scooter) {
  if (scooter.latitude == null || scooter.longitude == null) {
    return 'No GPS';
  }

  return '${scooter.latitude!.toStringAsFixed(4)}, ${scooter.longitude!.toStringAsFixed(4)}';
}

String _timeAgo(DateTime? date) {
  if (date == null) {
    return 'No signal';
  }

  final diff = DateTime.now().toUtc().difference(date.toUtc());
  if (diff.isNegative || diff.inMinutes < 1) {
    return 'Now';
  }

  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m';
  }

  if (diff.inHours < 24) {
    return '${diff.inHours}h';
  }

  return '${diff.inDays}d';
}
