import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:bicipalma_live/models/station.dart';
import 'package:bicipalma_live/services/gbfs_service.dart';

final languageProvider = StateProvider<Language>((ref) => Language.es);
final lastUpdatedProvider = StateProvider<DateTime?>((ref) => null);
final gbfsServiceProvider = Provider((ref) => GbfsService());

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
