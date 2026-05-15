import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bicipalma_live/providers/station_provider.dart';
import 'package:bicipalma_live/models/station.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// BiciPalma Live - Main Application File
/// 
/// This application provides a modern, map-centric interface for the BiciPalma bike-sharing system.
/// It features real-time data fetching, geolocation, and a responsive design for both mobile and desktop.


enum FilterType { all, manual, electric }

const LatLng _palmaFallback = LatLng(39.5767, 2.6557);

const Map<Language, Map<String, String>> translations = {
  Language.en: {
    'title': 'BiciPalma Live',
    'all': 'All',
    'manual': 'Manual',
    'electric': 'Electric',
    'docks': 'Docks',
    'total': 'Total',
    'favorites': 'Favorites',
    'nearby': 'Nearby',
    'nearest': 'Nearest stations',
    'updated': 'Updated',
    'waiting': 'Grant location to see nearby stations',
    'empty': 'No stations within 500m',
    'center': 'Center map',
    'refresh': 'Refresh location',
    'fallback': 'Using Palma fallback location',
    'stations': 'Stations',
  },
  Language.es: {
    'title': 'BiciPalma Live',
    'all': 'Todas',
    'manual': 'Manual',
    'electric': 'Eléc.',
    'docks': 'Anclajes',
    'total': 'Total',
    'favorites': 'Favoritas',
    'nearby': 'Cercanas',
    'nearest': 'Estaciones cercanas',
    'updated': 'Actualizado',
    'waiting': 'Permite el acceso a la ubicación',
    'empty': 'No hay estaciones a menos de 500m',
    'center': 'Centrar mapa',
    'refresh': 'Actualizar ubicación',
    'fallback': 'Usando ubicación de Palma',
    'stations': 'Estaciones',
  },
  Language.ca: {
    'title': 'BiciPalma Live',
    'all': 'Totes',
    'manual': 'Manual',
    'electric': 'Elèc.',
    'docks': 'Ancoratges',
    'total': 'Total',
    'favorites': 'Preferides',
    'nearby': 'Properes',
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
          surface: const Color(0xFFF8F9FA),
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
  // Location and Map State
  LatLng? _userLocation;
  final MapController _mapController = MapController();
  Timer? _locationUpdateTimer;
  bool _hasSetInitialCenter = false;
  bool _hasForcedLocation = false;
  bool _isLocating = false;
  bool _mapReady = false;

  // UI State
  FilterType _selectedFilter = FilterType.all;
  Station? _selectedStation;
  bool _showFavorites = false;
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
    final favorites = ref.watch(favoritesProvider);
    final localeStrings = translations[language]!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              title: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _isLocating = true);
                    if (_sheetController.isAttached) {
                      _sheetController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
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
                    if (_sheetController.isAttached) {
                      _sheetController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
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

              final displayStations = _showFavorites
                  ? (filteredStations
                      .where((station) => favorites.contains(station.id))
                      .toList()
                    ..sort((a, b) {
                      if (a.distance == null && b.distance == null) return 0;
                      if (a.distance == null) return 1;
                      if (b.distance == null) return -1;
                      return a.distance!.compareTo(b.distance!);
                    }))
                  : (filteredStations
                      .where((station) => station.distance != null)
                      .toList()
                    ..sort(
                      (a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0),
                    ));

              Widget buildSidebar(ScrollController? scrollController) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMobile) const SizedBox(height: kToolbarHeight + 8),
                          // Header Row with Title and Expand Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  localeStrings['stations'] ?? 'Estaciones',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                ListenableBuilder(
                                  listenable: _sheetController,
                                  builder: (context, child) {
                                    final isFull = _sheetController.isAttached && _sheetController.size > 0.8;
                                    return GestureDetector(
                                      onTap: () {
                                        _sheetController.animateTo(
                                          isFull ? 0.5 : 0.95,
                                          duration: const Duration(milliseconds: 350),
                                          curve: Curves.easeInOutCubic,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isFull ? Icons.keyboard_arrow_down : Icons.unfold_more,
                                          size: 18,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // View Toggle (Nearby / Favorites)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _showFavorites = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: !_showFavorites ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        boxShadow: !_showFavorites ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ] : [],
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.near_me,
                                            size: 14,
                                            color: !_showFavorites ? Theme.of(context).primaryColor : Colors.black54,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            localeStrings['nearby']!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: !_showFavorites ? FontWeight.bold : FontWeight.w500,
                                              color: !_showFavorites ? Theme.of(context).primaryColor : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _showFavorites = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _showFavorites ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        boxShadow: _showFavorites ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ] : [],
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 14,
                                            color: _showFavorites ? const Color(0xFFFFB300) : Colors.black54,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            localeStrings['favorites']!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: _showFavorites ? FontWeight.bold : FontWeight.w500,
                                              color: _showFavorites ? const Color(0xFFFFB300) : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Filters
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: FilterType.values.map((type) {
                                final label = type == FilterType.all
                                    ? localeStrings['all']!
                                    : type == FilterType.manual
                                    ? localeStrings['manual']!
                                    : localeStrings['electric']!;
                                final active = _selectedFilter == type;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedFilter = type),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: active ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: active ? FontWeight.bold : FontWeight.w500,
                                          color: active ? Theme.of(context).primaryColor : Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Status & Center
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.update, size: 12, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${localeStrings['updated']!}: ${_formatUpdated(lastUpdated)}',
                                    style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () async {
                                  setState(() => _isLocating = true);
                                  await _determinePosition(forceCenter: true);
                                  setState(() => _isLocating = false);
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      _hasForcedLocation ? Icons.info : Icons.my_location,
                                      size: 12,
                                      color: _hasForcedLocation ? Colors.amber.shade700 : Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _hasForcedLocation ? localeStrings['fallback']! : localeStrings['center']!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _hasForcedLocation ? Colors.amber.shade700 : Theme.of(context).primaryColor,
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
                    ),
                    Expanded(
                      child: CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          displayStations.isEmpty
                              ? SliverToBoxAdapter(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(48),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _showFavorites ? Icons.star_border : Icons.location_off_rounded,
                                            size: 48,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _showFavorites
                                                ? (language == Language.es ? 'No tienes estaciones favoritas' : 'No favorite stations')
                                                : (_userLocation == null ? localeStrings['waiting']! : localeStrings['empty']!),
                                            style: const TextStyle(color: Colors.black45, fontSize: 14),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ).animate().fadeIn(),
                                )
                              : SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate((context, index) {
                                      final station = displayStations[index];
                                      final isSelected = _selectedStation?.id == station.id;
                                      final isFavorite = favorites.contains(station.id);

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
                                              0.0,
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
                                                color: Colors.black.withValues(
                                                  alpha: 0.04,
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
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          station.name,
                                                          style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        if (station.distance != null)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4),
                                                            child: Text(
                                                              _formatDistance(station.distance!),
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors.grey.shade600,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      isFavorite ? Icons.star : Icons.star_border,
                                                      color: isFavorite ? const Color(0xFFFFB300) : Colors.grey,
                                                      size: 20,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () {
                                                      ref.read(favoritesProvider.notifier).toggleFavorite(station.id);
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _buildStatBadge(
                                                    localeStrings['total']!,
                                                    station.numBikesAvailable,
                                                    const Color(0xFF6200EE),
                                                  ),
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
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                      .animate()
                                      .fadeIn(
                                        delay: Duration(milliseconds: 30 * index),
                                      )
                                      .slideX(begin: 0.05, end: 0);
                                }, childCount: displayStations.length),
                              ),
                            ),
                        ],
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
                      onTap: (pos, latlng) {
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
                                    ).primaryColor.withValues(alpha: 0.2),
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
                                            ).primaryColor.withValues(alpha: 0.4),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ...(() {
                            // Z-Index Logic: We move the selected station to the end of the list
                            // so that its marker (and info bubble) is rendered on top of all others.
                            final list = List<Station>.from(stationsWithDistance);
                            if (_selectedStation != null) {
                              final index = list.indexWhere((s) => s.id == _selectedStation!.id);
                              if (index != -1) {
                                final selected = list.removeAt(index);
                                list.add(selected); 
                              }
                            }
                            return list;
                          })().map((station) {
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
                              width: isSelected ? 240 : 60,
                              height: isSelected ? 240 : 60,
                              alignment: Alignment.center,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  if (isSelected)
                                    Positioned(
                                      bottom: 140, // Center is at 120, so 140 is 20px above center
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 240,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.15),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        station.name,
                                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(station.id),
                                                      child: Icon(
                                                        favorites.contains(station.id) ? Icons.star : Icons.star_border,
                                                        color: favorites.contains(station.id) ? const Color(0xFFFFB300) : Colors.grey,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    GestureDetector(
                                                      onTap: () => setState(() => _selectedStation = null),
                                                      child: const Icon(Icons.close, size: 20, color: Colors.black45),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    _buildCompactStat(Icons.pedal_bike, '${station.numBikesAvailable}', localeStrings['total']!, const Color(0xFF6200EE)),
                                                    _buildCompactStat(Icons.directions_bike, '${station.numManualAvailable}', localeStrings['manual']!, const Color(0xFF10B981)),
                                                    _buildCompactStat(Icons.electric_bike, '${station.numElectricAvailable}', localeStrings['electric']!, const Color(0xFF3B82F6)),
                                                    _buildCompactStat(Icons.local_parking, '${station.numDocksAvailable}', localeStrings['docks']!, const Color(0xFF6B7280)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Arrow / Pointer
                                          SizedBox(
                                            width: 16,
                                            height: 8,
                                            child: CustomPaint(
                                              painter: TrianglePainter(color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                                    ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedStation = station);
                                      if (isMobile && _sheetController.isAttached) {
                                        _sheetController.animateTo(
                                          0.0,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeOut,
                                        );
                                      }
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
                                      width: isSelected ? 52 : 40,
                                      height: isSelected ? 52 : 40,
                                      decoration: BoxDecoration(
                                        color: markerColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: isSelected ? 3 : 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: markerColor.withValues(alpha: isSelected ? 0.6 : 0.3),
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
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                    ],
                  );

              if (isMobile) {
                return Stack(
                  children: [
                    mapContent,
                    DraggableScrollableSheet(
                      controller: _sheetController,
                      initialChildSize: 0.5,
                      minChildSize: 0.0,
                      maxChildSize: 0.95,
                      snap: true,
                      snapSizes: const [0.0, 0.5, 0.8, 0.95],
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
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
                                    if (_sheetController.size <= 0.1) {
                                      _sheetController.animateTo(
                                        0.4,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    } else {
                                      _sheetController.animateTo(
                                        0.0,
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
                      Positioned(
                        bottom: 16,
                      right: 16,
                      child: ListenableBuilder(
                        listenable: _sheetController,
                        builder: (context, child) {
                          final isHidden = _sheetController.isAttached && _sheetController.size < 0.1;
                          if (!isHidden) return const SizedBox.shrink();
                          return FloatingActionButton.extended(
                            onPressed: () {
                              _sheetController.animateTo(
                                0.5,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                            backgroundColor: Theme.of(context).primaryColor,
                            icon: const Icon(Icons.list, color: Colors.white),
                            label: Text(
                              localeStrings['stations']!,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ).animate().scale(curve: Curves.easeOutBack);
                        },
                      ),
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

  Widget _buildCompactStat(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
