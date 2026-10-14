import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';
import '../../../location/data/providers.dart';
import '../../../location/domain/device_location.dart';
import '../../../ride/domain/parking_zone.dart';
import '../../../scooters/data/providers.dart';
import '../../../scooters/domain/scooter.dart';
import '../../../scooters/domain/scooter_code_translator.dart';
import '../../../scooters/presentation/widgets/scooter_card.dart';
import '../../../scooters/presentation/widgets/scooter_detail_sheet.dart';
import '../widgets/map_marker_generator.dart';

class ScooterMapScreen extends ConsumerStatefulWidget {
  const ScooterMapScreen({this.listOpen = false, super.key});

  final bool listOpen;

  @override
  ConsumerState<ScooterMapScreen> createState() => _ScooterMapScreenState();
}

class _ScooterMapScreenState extends ConsumerState<ScooterMapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  bool _mapLoaded = false;
  bool _mapFailed = false;
  late bool _showList;
  String? _selectedScooterId;

  bool get _supportsNativeMap =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _showList = true;
  }

  void _focusScooter(Scooter scooter) {
    setState(() => _selectedScooterId = scooter.id);
    if (scooter.latitude != null && scooter.longitude != null) {
      _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(scooter.longitude!, scooter.latitude!),
          ),
          zoom: 16.5,
          pitch: 42.0,
        ),
      );
    }
    final scooters = ref.read(scooterListProvider).valueOrNull;
    if (scooters != null) {
      _updateScooterMarkers(scooters);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationControllerProvider);
    final location = locationState.location;
    final scootersAsync = ref.watch(scooterListProvider);

    ref.listen<LocationState>(locationControllerProvider, (previous, next) {
      final nextLocation = next.location;
      if (next.status == LocationStatus.ready &&
          nextLocation != null &&
          nextLocation != previous?.location) {
        _moveTo(nextLocation);
      }
    });

    // Update map markers whenever scooters change
    scootersAsync.whenData((scooters) {
      _updateScooterMarkers(scooters);
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

          // Top navigation bar matching mockup (Hamburger left, ISOKO logo center)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MapIconButton(
                    tooltip: 'Menu',
                    icon: Icons.menu_rounded,
                    onPressed: () => context.go('/menu'),
                  ),
                  const IsokoLogo(height: 38),
                  const SizedBox(width: 46), // Balance spacing
                ],
              ),
            ),
          ),

          // Recenter FAB
          Positioned(
            right: 18,
            bottom: _showList ? 340 : 180,
            child: _MapIconButton(
              tooltip: 'Center on my location',
              icon: Icons.my_location_rounded,
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

          // Bottom panel: scooter list / status
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: _MapBottomPanel(
                location: location,
                listOpen: _showList,
                selectedScooterId: _selectedScooterId,
                scootersAsync: scootersAsync,
                onFocusScooter: _focusScooter,
                onSelectScooter: _showScooterDetail,
                onToggleList: () => setState(() => _showList = !_showList),
                onScanQr: () => context.go('/scan-qr'),
                onManualCode: () => context.go('/unlock-number'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScooterDetail(Scooter scooter) {
    ref.read(selectedScooterProvider.notifier).state = scooter;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScooterDetailSheet(
        scooter: scooter,
        onUnlock: () {
          Navigator.of(ctx).pop();
          context.go('/unlocking');
        },
        onScanQr: () {
          Navigator.of(ctx).pop();
          context.go('/scan-qr');
        },
        onEnterCode: () {
          Navigator.of(ctx).pop();
          context.go('/unlock-number');
        },
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
              if (mounted && !_mapLoaded) setState(() => _mapLoaded = true);
            },
            onMapLoadErrorListener: (error) {
              debugPrint('Mapbox load notice: $error');
            },
          ),
        ),
      ],
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    if (mounted && !_mapLoaded) {
      setState(() => _mapLoaded = true);
    }

    try {
      _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();

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
          marginBottom: _showList ? 340 : 180,
        ),
      );
      await mapboxMap.attribution.updateSettings(
        AttributionSettings(
          position: OrnamentPosition.BOTTOM_RIGHT,
          marginRight: 8,
          marginBottom: _showList ? 340 : 180,
        ),
      );

      final scooters = ref.read(scooterListProvider).valueOrNull;
      if (scooters != null) {
        await _updateScooterMarkers(scooters);
      }
    } catch (_) {
      if (mounted) setState(() => _mapFailed = true);
    }
  }

  Future<void> _updateScooterMarkers(List<Scooter> scooters) async {
    final manager = _pointAnnotationManager;
    if (manager == null) return;

    try {
      await manager.deleteAll();
      final options = <PointAnnotationOptions>[];

      // 1. Generate Custom Scooter Pin Icons
      final normalPin = await MapMarkerGenerator.generateScooterMarker();
      final selectedPin = await MapMarkerGenerator.generateScooterMarker(isSelected: true);

      for (final s in scooters) {
        if (s.latitude != null && s.longitude != null) {
          final isSelected = s.id == _selectedScooterId;
          final pinImage = isSelected
              ? selectedPin
              : (s.batteryPercent != null
                  ? await MapMarkerGenerator.generateScooterMarker(
                      batteryPercent: s.batteryPercent,
                    )
                  : normalPin);

          options.add(
            PointAnnotationOptions(
              geometry: Point(coordinates: Position(s.longitude!, s.latitude!)),
              image: pinImage,
              iconSize: isSelected ? 0.72 : 0.60,
              iconAnchor: IconAnchor.BOTTOM,
              textField: ScooterCodeTranslator.formatDisplay(s.publicCode),
              textColor: Colors.white.toARGB32(),
              textSize: 12.0,
              textHaloColor: const Color(0xFF0C100E).toARGB32(),
              textHaloWidth: 2.0,
              textOffset: [0.0, 1.3],
            ),
          );
        }
      }

      // 2. Add Designated Kigali Parking Stations with "P" Pins
      final parkingPin = await MapMarkerGenerator.generateParkingMarker();
      for (final station in ParkingZoneValidator.stations) {
        options.add(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(station.longitude, station.latitude)),
            image: parkingPin,
            iconSize: 0.52,
            iconAnchor: IconAnchor.BOTTOM,
            textField: station.name,
            textColor: const Color(0xFF64B5F6).toARGB32(),
            textSize: 11.0,
            textHaloColor: const Color(0xFF0C100E).toARGB32(),
            textHaloWidth: 1.8,
            textOffset: [0.0, 1.2],
          ),
        );
      }

      if (options.isNotEmpty) {
        await manager.createMulti(options);
      }
    } catch (_) {
      // Ignore marker render glitches
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyThemeToMap();
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    if (mounted && !_mapLoaded) {
      setState(() => _mapLoaded = true);
    }
    await _applyThemeToMap();
  }

  Future<void> _applyThemeToMap() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      await _mapboxMap?.style.setStyleImportConfigProperty(
        'basemap',
        'lightPreset',
        isDark ? 'night' : 'day',
      );
      await _mapboxMap?.style.setStyleImportConfigProperty(
        'basemap',
        'theme',
        isDark ? 'monochrome' : 'standard',
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
        zoom: 16.0,
        pitch: 38.0,
      ),
    );
  }
}

class _MapBottomPanel extends StatelessWidget {
  const _MapBottomPanel({
    required this.location,
    required this.listOpen,
    this.selectedScooterId,
    required this.scootersAsync,
    required this.onFocusScooter,
    required this.onSelectScooter,
    required this.onToggleList,
    required this.onScanQr,
    required this.onManualCode,
  });

  final DeviceLocation location;
  final bool listOpen;
  final String? selectedScooterId;
  final AsyncValue<List<Scooter>> scootersAsync;
  final void Function(Scooter) onFocusScooter;
  final void Function(Scooter) onSelectScooter;
  final VoidCallback onToggleList;
  final VoidCallback onScanQr;
  final VoidCallback onManualCode;

  @override
  Widget build(BuildContext context) {
    final scooters = scootersAsync.valueOrNull ?? [];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 680),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? const Color(0xB3000000)
                : const Color(0x26000000),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Location Header Row matching find-scooter-screen.png
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF232E27)
                      : const Color(0xFFE8F6EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.electric_scooter_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '23rd Avenue Street',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: onToggleList,
                      child: Row(
                        children: [
                          Text(
                            '${scooters.length} Scooters available',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            listOpen
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: context.textSecondary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Distance badge on top right
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF1B2B22)
                      : const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppTheme.primaryGreen.withAlpha(80)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      color: AppTheme.primaryGreen,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '3.2km',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Horizontal Scooters Carousel (when expanded)
          if (listOpen && scooters.isNotEmpty) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 142,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: scooters.length,
                itemBuilder: (ctx, i) {
                  final s = scooters[i];
                  return ScooterCard(
                    scooter: s,
                    isSelected: s.id == selectedScooterId,
                    isHorizontal: true,
                    onTap: () {
                      onFocusScooter(s);
                      onSelectScooter(s);
                    },
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Large Green Scan Now Button matching mockup
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onScanQr,
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 22,
              ),
              label: Text(
                context.tr.scanNow,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
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
          backgroundColor: context.isDarkMode
              ? const Color(0xD9141816)
              : const Color(0xE6FFFFFF),
          foregroundColor: context.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: context.isDarkMode ? 0 : 3,
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
