import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey;
  WeatherService([this.apiKey = '']);

  Future<Map<String, dynamic>?> fetchWeather(double lat, double lon) async {
    if (apiKey.trim().isNotEmpty) {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      print('OpenWeather fetch failed (${response.statusCode}): ${response.body}');
    }

    // Fallback provider that does not require an API key.
    final fallbackUrl = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=relativehumidity_2m&timezone=auto',
    );
    final fallbackResponse = await http.get(fallbackUrl);
    if (fallbackResponse.statusCode != 200) {
      print(
        'Open-Meteo fetch failed (${fallbackResponse.statusCode}): ${fallbackResponse.body}',
      );
      return null;
    }

    final data = json.decode(fallbackResponse.body) as Map<String, dynamic>;
    final currentWeather =
        (data['current_weather'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final hourly = (data['hourly'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final humiditySeries = (hourly['relativehumidity_2m'] as List?) ?? const [];

    final temp = (currentWeather['temperature'] as num?)?.toDouble() ?? 0.0;
    final humidity = humiditySeries.isNotEmpty
        ? ((humiditySeries.first as num?)?.toDouble() ?? 0.0)
        : 0.0;

    return {
      'main': {
        'temp': temp,
        'humidity': humidity,
      },
      'rain': {'1h': 0.0},
      'source': 'open-meteo',
    };
  }
}
