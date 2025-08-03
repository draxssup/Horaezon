import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '6ee17fc0acb768001a08ff30323303ee';
  final String city = 'Mumbai';

  Future<Map<String, dynamic>?> fetchWeather() async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'temp': data['main']['temp'],
        'condition': data['weather'][0]['main'],
        'icon': data['weather'][0]['icon']
      };
    }
    return null;
  }

  String getWeatherEmoji(String condition, String icon) {
    final isNight = icon.endsWith('n');
    switch (condition.toLowerCase()) {
      case 'clear':
        return isNight ? '🌙' : '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌡️';
    }
  }
}
