import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';
import '../../../location/data/providers.dart';
import '../../../location/domain/device_location.dart';

class ScooterMapScreen extends ConsumerStatefulWidget {
  const ScooterMapScreen({this.listOpen = false, super.key});

  final bool listOpen;

  @override
  ConsumerState<ScooterMapScreen> createState() => _ScooterMapScreenState();
}

class _ScooterMapScreenState extends ConsumerState<ScooterMapScreen> {
  MapboxMap? _mapboxMap;
  bool _mapLoaded = false;
  bool _mapFailed = false;

  bool get _supportsNativeMap =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationControllerProvider);
    final location = locationState.location;

    ref.listen<LocationState>(locationControllerProvider, (previous, next) {
      final nextLocation = next.location;
      if (next.status == LocationStatus.ready &&
          nextLocation != null &&
          nextLocation != previous?.location) {
        _moveTo(nextLocation);
      }
    });

    if (location == null) {
      return _LocationRequired(
        busy: locationState.isBusy,
        onEnable: () => context.go('/enable-location'),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap(location)),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(94),
                      Colors.transparent,
                      Colors.black.withAlpha(42),
                    ],
                    stops: const [0, 0.18, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MapIconButton(
                    tooltip: 'Menu',
                    icon: Icons.menu,
                    onPressed: () => context.go('/menu'),
                  ),
                  const IsokoLogo(height: 36),
                  const SizedBox.square(dimension: 46),
                ],
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: widget.listOpen ? 252 : 226,
            child: _MapIconButton(
              tooltip: 'Center on my location',
              icon: Icons.my_location,
              onPressed: locationState.isBusy
                  ? null
                  : () async {
                      await ref
                          .read(locationControllerProvider.notifier)
                          .refreshLocation();
                      final current = ref.read(locationControllerProvider);
                      if (current.location != null) {
                        await _moveTo(current.location!);
                      }
                    },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: _MapBottomPanel(
                location: location,
                listOpen: widget.listOpen,
                onPrimary: () => context.go(
                  widget.listOpen ? '/enable-camera' : '/scooter-list',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(DeviceLocation location) {
    if (!AppConfig.hasMapboxAccessToken) {
      return const _MapUnavailable(
        icon: Icons.map_outlined,
        message: 'The map is temporarily unavailable.',
      );
    }

    if (!_supportsNativeMap) {
      return const _MapUnavailable(
        icon: Icons.phone_android,
        message: 'Open ISOKO on Android or iPhone to view the live map.',
      );
    }

    if (_mapFailed) {
      return _MapUnavailable(
        icon: Icons.cloud_off_outlined,
        message: 'The map could not be loaded.',
        onRetry: () => setState(() {
          _mapFailed = false;
          _mapLoaded = false;
        }),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: MapWidget(
            key: const ValueKey('isoko-map'),
            styleUri: MapboxStyles.STANDARD,
            viewport: CameraViewportState(
              center: Point(
                coordinates: Position(
                  location.longitude,
                  location.latitude,
                ),
              ),
              zoom: 15.5,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onMapLoadedListener: (_) {
              if (mounted) setState(() => _mapLoaded = true);
            },
            onMapLoadErrorListener: (_) {
              if (mounted && !_mapLoaded) {
                setState(() => _mapFailed = true);
              }
            },
          ),
        ),
        if (!_mapLoaded)
          const Positioned.fill(
            child: ColoredBox(
              color: AppTheme.backgroundColor,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    try {
      await mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          pulsingColor: AppTheme.primaryGreen.toARGB32(),
          showAccuracyRing: true,
          accuracyRingColor: AppTheme.primaryGreen.withAlpha(44).toARGB32(),
          accuracyRingBorderColor: AppTheme.primaryGreen.toARGB32(),
        ),
      );
      await mapboxMap.compass.updateSettings(
        CompassSettings(
          enabled: true,
          position: OrnamentPosition.TOP_RIGHT,
          marginTop: 82,
          marginRight: 14,
        ),
      );
      await mapboxMap.scaleBar.updateSettings(
        ScaleBarSettings(enabled: false),
      );
      await mapboxMap.logo.updateSettings(
        LogoSettings(
          position: OrnamentPosition.BOTTOM_LEFT,
          marginLeft: 12,
          marginBottom: widget.listOpen ? 232 : 206,
        ),
      );
      await mapboxMap.attribution.updateSettings(
        AttributionSettings(
          position: OrnamentPosition.BOTTOM_RIGHT,
          marginRight: 8,
          marginBottom: widget.listOpen ? 232 : 206,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _mapFailed = true);
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    try {
      await _mapboxMap?.style.setStyleImportConfigProperty(
        'basemap',
        'lightPreset',
        'night',
      );
      await _mapboxMap?.style.setStyleImportConfigProperty(
        'basemap',
        'theme',
        'monochrome',
      );
    } catch (_) {
      // The map remains usable if a future style omits these properties.
    }
  }

  Future<void> _moveTo(DeviceLocation location) async {
    await _mapboxMap?.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(location.longitude, location.latitude),
        ),
        zoom: 15.5,
      ),
    );
  }
}

class _MapBottomPanel extends StatelessWidget {
  const _MapBottomPanel({
    required this.location,
    required this.listOpen,
    required this.onPrimary,
  });

  final DeviceLocation location;
  final bool listOpen;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final accuracy = location.accuracyMeters.isFinite
        ? location.accuracyMeters.round().clamp(0, 9999)
        : null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 680),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.near_me, color: AppTheme.primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current location',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      accuracy == null
                          ? 'Position acquired'
                          : 'Accuracy within about $accuracy m',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (listOpen) ...[
            const SizedBox(height: 14),
            const Divider(color: AppTheme.cardBorder),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.electric_scooter_outlined,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No scooters available nearby',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPrimary,
              icon: Icon(
                listOpen ? Icons.qr_code_scanner : Icons.list_alt_outlined,
              ),
              label: Text(listOpen ? 'Scan scooter' : 'View nearby scooters'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 46,
      child: IconButton.filled(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xD9141816),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                IconButton.filled(
                  tooltip: 'Retry map',
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationRequired extends StatelessWidget {
  const _LocationRequired({required this.busy, required this.onEnable});

  final bool busy;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_off_outlined,
                  size: 52,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 18),
                Text(
                  'Location is required',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Allow location to center the map on your position.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 240,
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : onEnable,
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Enable location'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
