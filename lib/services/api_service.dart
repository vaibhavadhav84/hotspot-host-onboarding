import 'package:dio/dio.dart';
import '../models/experience_model.dart';

class ApiService {
  final Dio _dio = Dio();

  Future<List<Experience>> fetchExperiences() async {
    const url =
        'https://staging.chamberofsecrets.8club.co/v1/experiences?active=true';
    final response = await _dio.get(url);

    if (response.statusCode == 200) {
      final List data = response.data['data']['experiences'];
      return data.map((e) => Experience.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load experiences');
    }
  }
}
