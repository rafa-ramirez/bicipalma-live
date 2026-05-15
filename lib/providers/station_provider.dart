import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:bicipalma_live/models/station.dart';
import 'package:bicipalma_live/services/gbfs_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

final languageProvider = StateProvider<Language>((ref) => Language.es);
final lastUpdatedProvider = StateProvider<DateTime?>((ref) => null);
final gbfsServiceProvider = Provider((ref) => GbfsService());

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  static const _key = 'favorite_stations';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];
    state = favorites.toSet();
  }

  Future<void> toggleFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final newFavorites = state.contains(stationId)
        ? (state.toSet()..remove(stationId))
        : (state.toSet()..add(stationId));
    
    state = newFavorites;
    await prefs.setStringList(_key, newFavorites.toList());
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

final stationListProvider = StreamProvider.autoDispose<List<Station>>((ref) {
  final gbfsService = ref.watch(gbfsServiceProvider);
  final language = ref.watch(languageProvider);
  final controller = StreamController<List<Station>>();

  void fetchAndAddStations() async {
    try {
      final stations = await gbfsService.fetchStations(language);
      controller.add(stations);
      ref.read(lastUpdatedProvider.notifier).state = DateTime.now();
    } catch (e) {
      controller.addError(e);
    }
  }

  fetchAndAddStations(); // Initial fetch

  final timer = Timer.periodic(const Duration(seconds: 60), (timer) {
    fetchAndAddStations();
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
