import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bicipalma_live/providers/station_provider.dart';
import 'package:bicipalma_live/models/station.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum FilterType { all, manual, electric }

const LatLng _palmaFallback = LatLng(39.5767, 2.6557);

const Map<Language, Map<String, String>> translations = {
  Language.en: {
    'title': 'BiciPalma Live',
    'all': 'All',
    'manual': 'Manual',
    'electric': 'Electric',
    'docks': 'Docks',
    'nearest': 'Nearest stations',
    'updated': 'Updated',
    'waiting': 'Grant location to see nearby stations',
    'empty': 'No stations within 500m',
    'center': 'Center map',
    'refresh': 'Refresh location',
    'fallback': 'Using Palma fallback location',
  },
  Language.es: {
    'title': 'BiciPalma Live',
    'all': 'Todas',
    'manual': 'Manual',
    'electric': 'Eléc.',
    'docks': 'Anclajes',
    'nearest': 'Estaciones cercanas',
    'updated': 'Actualizado',
    'waiting': 'Permite el acceso a la ubicación',
    'empty': 'No hay estaciones a menos de 500m',
    'center': 'Centrar mapa',
    'refresh': 'Actualizar ubicación',
    'fallback': 'Usando ubicación de Palma',
  },
  Language.ca: {
    'title': 'BiciPalma Live',
    'all': 'Totes',
    'manual': 'Manual',
    'electric': 'Elèc.',
    'docks': 'Ancoratges',
    'nearest': 'Estacions properes',
    'updated': 'Actualitzat',
    'waiting': 'Permet l’accés a la ubicació',
    'empty': 'No hi ha estacions a menys de 500m',
    'center': 'Centrar mapa',
    'refresh': 'Actualitzar ubicació',
    'fallback': 'S’utilitza la ubicació de Palma',
  },
};

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.outfitTextTheme();

    return MaterialApp(
      title: 'BiciPalma Live',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE),
          primary: const Color(0xFF6200EE),
          secondary: const Color(0xFF03DAC5),
          background: const Color(0xFFF8F9FA),
          surface: Colors.white,
        ),
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 8,
          shadowColor: Color(0x14000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          color: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  LatLng? _userLocation;
  final MapController _mapController = MapController();
  Timer? _locationUpdateTimer;
  bool _hasSetInitialCenter = false;
  bool _hasForcedLocation = false;
  bool _isLocating = false;
  bool _mapReady = false;
  FilterType _selectedFilter = FilterType.all;
  Station? _selectedStation;
  late final AnimationController _pulseController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.75, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sheetController.dispose();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition({bool forceCenter = false}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = location;
        _hasForcedLocation = false;
      });

      if (_mapReady && (!_hasSetInitialCenter || forceCenter)) {
        _mapController.move(location, 14.0);
        _hasSetInitialCenter = true;
      }
    } catch (_) {
      if (!_hasForcedLocation) {
        setState(() {
          _userLocation = _palmaFallback;
          _hasForcedLocation = true;
        });
        if (_mapReady && (!_hasSetInitialCenter || forceCenter)) {
          _mapController.move(_palmaFallback, 13.0);
          _hasSetInitialCenter = true;
        }
      }
    }
  }

  void _startLocationUpdates() {
    _determinePosition();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _determinePosition();
    });
  }

  String _formatDistance(double meters) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatUpdated(DateTime? updated) {
    if (updated == null) return '--:--';
    return DateFormat.Hm().format(updated);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lastUpdated = ref.watch(lastUpdatedProvider);
    final stationListAsyncValue = ref.watch(stationListProvider);
    final localeStrings = translations[language]!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.8),
              title: GestureDetector(
                onTap: () async {
                  setState(() => _isLocating = true);
                  await _determinePosition(forceCenter: true);
                  setState(() => _isLocating = false);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pedal_bike,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(localeStrings['title']!),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: _isLocating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).primaryColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.my_location,
                          color: Theme.of(context).primaryColor,
                        ),
                  tooltip: localeStrings['refresh'],
                  onPressed: () async {
                    setState(() {
                      _isLocating = true;
                    });
                    await _determinePosition(forceCenter: true);
                    setState(() {
                      _isLocating = false;
                    });
                  },
                ),
                PopupMenuButton<Language>(
                  icon: Icon(
                    Icons.language,
                    color: Theme.of(context).primaryColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  itemBuilder: (context) => Language.values.map((lang) {
                    return PopupMenuItem<Language>(
                      value: lang,
                      child: Text(
                        lang.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onSelected: (selected) {
                    ref.read(languageProvider.notifier).state = selected;
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;

          return stationListAsyncValue.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (stations) {
              final stationsWithDistance = stations.map((station) {
                if (_userLocation == null) return station;
                final distance = Geolocator.distanceBetween(
                  _userLocation!.latitude,
                  _userLocation!.longitude,
                  station.lat,
                  station.lon,
                );
                return station.copyWith(distance: distance);
              }).toList();

              final filteredStations = stationsWithDistance.where((station) {
                switch (_selectedFilter) {
                  case FilterType.manual:
                    return station.numManualAvailable > 0;
                  case FilterType.electric:
                    return station.numElectricAvailable > 0;
                  case FilterType.all:
                    return true;
                }
              }).toList();

              final nearestStations =
                  filteredStations
                      .where((station) => station.distance != null)
                      .toList()
                    ..sort(
                      (a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0),
                    );

              Widget buildSidebar(ScrollController? scrollController) {
                return CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(height: isMobile ? 0 : kToolbarHeight + 24),
                          Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.08),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.near_me,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          localeStrings['nearest']!,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Row(
                                        children: FilterType.values.map((type) {
                                          final label = type == FilterType.all
                                              ? localeStrings['all']!
                                              : type == FilterType.manual
                                              ? localeStrings['manual']!
                                              : localeStrings['electric']!;
                                          final active =
                                              _selectedFilter == type;
                                          return Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedFilter = type;
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: active
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: active
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                  0.05,
                                                                ),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: active
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: active
                                                        ? Theme.of(
                                                            context,
                                                          ).primaryColor
                                                        : Colors.black54,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.update,
                                              size: 14,
                                              color: Colors.black45,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${localeStrings['updated']!}: ${_formatUpdated(lastUpdated)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black45,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            setState(() => _isLocating = true);
                                            await _determinePosition(
                                              forceCenter: true,
                                            );
                                            setState(() => _isLocating = false);
                                          },
                                          child: Row(
                                            children: [
                                              if (_hasForcedLocation)
                                                Icon(
                                                  Icons.info,
                                                  size: 14,
                                                  color: Colors.amber.shade600,
                                                )
                                              else
                                                Icon(
                                                  Icons.my_location,
                                                  size: 14,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _hasForcedLocation
                                                    ? localeStrings['fallback']!
                                                    : localeStrings['center']!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _hasForcedLocation
                                                      ? Colors.amber.shade700
                                                      : Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(
                                begin: -0.1,
                                end: 0,
                                curve: Curves.easeOutQuad,
                              ),
                        ],
                      ),
                    ),
                    nearestStations.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_off_rounded,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _userLocation == null
                                          ? localeStrings['waiting']!
                                          : localeStrings['empty']!,
                                      style: const TextStyle(
                                        color: Colors.black45,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final station = nearestStations[index];
                                final isSelected =
                                    _selectedStation?.id == station.id;

                                return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          setState(() {
                                            _selectedStation = station;
                                          });
                                          _mapController.move(
                                            LatLng(station.lat, station.lon),
                                            16.0,
                                          );
                                          if (isMobile &&
                                              _sheetController.isAttached) {
                                            _sheetController.animateTo(
                                              0.1,
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeOut,
                                            );
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Theme.of(
                                                      context,
                                                    ).primaryColor
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.04,
                                                ),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      station.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  if (station.distance != null)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey
                                                            .shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .directions_walk,
                                                            size: 12,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            _formatDistance(
                                                              station.distance!,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey
                                                                  .shade700,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _buildStatBadge(
                                                    localeStrings['manual']!,
                                                    station.numManualAvailable,
                                                    const Color(0xFF10B981),
                                                  ),
                                                  _buildStatBadge(
                                                    localeStrings['electric']!,
                                                    station
                                                        .numElectricAvailable,
                                                    const Color(0xFF3B82F6),
                                                  ),
                                                  _buildStatBadge(
                                                    localeStrings['docks']!,
                                                    station.numDocksAvailable,
                                                    const Color(0xFF6B7280),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(
                                      delay: Duration(milliseconds: 50 * index),
                                    )
                                    .slideX(begin: 0.1, end: 0);
                              }, childCount: nearestStations.length),
                            ),
                          ),
                  ],
                );
              }

              Widget mapContent = Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          _userLocation ?? const LatLng(39.5696, 2.6502),
                      initialZoom: 14.0,
                      minZoom: 10,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () {
                        setState(() => _mapReady = true);
                        if (_userLocation != null && !_hasSetInitialCenter) {
                          _mapController.move(_userLocation!, 14.0);
                          _hasSetInitialCenter = true;
                        }
                      },
                      onTap: (_, __) {
                        if (_selectedStation != null) {
                          setState(() => _selectedStation = null);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                      MarkerLayer(
                        markers: [
                          if (_userLocation != null)
                            Marker(
                              point: _userLocation!,
                              width: 60,
                              height: 60,
                              child: ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.2),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).primaryColor,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.4),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ...stationsWithDistance.map((station) {
                            // Determine display count and color based on active filter
                            final int displayCount;
                            final bool isEmpty;
                            final bool isLow;
                            switch (_selectedFilter) {
                              case FilterType.manual:
                                displayCount = station.numManualAvailable;
                                isEmpty = displayCount == 0;
                                isLow = displayCount < 2 && !isEmpty;
                              case FilterType.electric:
                                displayCount = station.numElectricAvailable;
                                isEmpty = displayCount == 0;
                                isLow = displayCount < 2 && !isEmpty;
                              case FilterType.all:
                                displayCount = station.numBikesAvailable;
                                isEmpty = displayCount == 0;
                                isLow = displayCount < 3 && !isEmpty;
                            }
                            final markerColor = isEmpty
                                ? const Color(0xFFEF4444)
                                : (isLow
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981));

                            final isSelected =
                                _selectedStation?.id == station.id;

                            return Marker(
                              key: ValueKey(station.id),
                              point: LatLng(station.lat, station.lon),
                              width: 56,
                              height: 56,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedStation = station);
                                  Future.microtask(
                                    () => _mapController.move(
                                      LatLng(station.lat, station.lon),
                                      16.0,
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  margin: EdgeInsets.all(isSelected ? 2 : 8),
                                  decoration: BoxDecoration(
                                    color: markerColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: isSelected ? 3 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: markerColor.withOpacity(
                                          isSelected ? 0.6 : 0.3,
                                        ),
                                        blurRadius: isSelected ? 18 : 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$displayCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            'CartoDB Voyager',
                            onTap: () => {},
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_selectedStation != null)
                    Positioned(
                          bottom: isMobile
                              ? MediaQuery.of(context).size.height * 0.1 + 16
                              : 24,
                          left: isMobile ? 16 : 24,
                          right: isMobile ? 16 : 24,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _selectedStation!.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              if (_selectedStation!.distance !=
                                                  null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.directions_walk,
                                                        size: 14,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatDistance(
                                                          _selectedStation!
                                                              .distance!,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors
                                                              .grey
                                                              .shade700,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _selectedStation = null;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _buildInfoChip(
                                          Icons.pedal_bike,
                                          'Total',
                                          '${_selectedStation!.numBikesAvailable}',
                                          const Color(0xFF6200EE),
                                        ),
                                        _buildInfoChip(
                                          Icons.directions_bike,
                                          'Manual',
                                          '${_selectedStation!.numManualAvailable}',
                                          const Color(0xFF10B981),
                                        ),
                                        _buildInfoChip(
                                          Icons.electric_bike,
                                          'Electric',
                                          '${_selectedStation!.numElectricAvailable}',
                                          const Color(0xFF3B82F6),
                                        ),
                                        _buildInfoChip(
                                          Icons.local_parking,
                                          localeStrings['docks']!,
                                          '${_selectedStation!.numDocksAvailable}',
                                          const Color(0xFF6B7280),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .slideY(
                          begin: 1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(),
                ],
              );

              if (isMobile) {
                return Stack(
                  children: [
                    mapContent,
                    DraggableScrollableSheet(
                      controller: _sheetController,
                      initialChildSize: 0.4,
                      minChildSize: 0.1,
                      maxChildSize: 0.4,
                      snap: true,
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 16,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (_sheetController.isAttached) {
                                    if (_sheetController.size < 0.2) {
                                      _sheetController.animateTo(
                                        0.4,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    } else {
                                      _sheetController.animateTo(
                                        0.1,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    width: 40,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(child: buildSidebar(scrollController)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Container(
                    width: 380,
                    color: const Color(0xFFF8F9FA),
                    child: buildSidebar(null),
                  ),
                  Expanded(child: mapContent),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
