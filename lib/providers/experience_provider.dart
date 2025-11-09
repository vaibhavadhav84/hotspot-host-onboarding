import 'package:flutter_riverpod/legacy.dart';
import '../models/experience_model.dart';
import '../services/api_service.dart';

final experienceProvider =
    StateNotifierProvider<ExperienceNotifier, List<Experience>>((ref) {
      return ExperienceNotifier();
    });

class ExperienceNotifier extends StateNotifier<List<Experience>> {
  ExperienceNotifier() : super([]);

  final ApiService _api = ApiService();

  Future<void> loadExperiences() async {
    final data = await _api.fetchExperiences();
    state = data;
  }
}
