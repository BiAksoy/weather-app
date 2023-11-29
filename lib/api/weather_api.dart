import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/model/weather_model.dart';
import 'package:weather_app/secrets.dart';

class WeatherAPI {
  Future<Weather> getWeatherBySearchedLocation(String location) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$location&units=metric&APPID=$openWeatherAPIKey',
        ),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch weather data. Please try again later.',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Weather.fromJson(data);
    } catch (e) {
      throw Exception(
        'An unexpected error occurred. Please try again later.',
      );
    }
  }

  Future<Weather> getWeatherByCurrentPosition(Position position) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&units=metric&APPID=$openWeatherAPIKey',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch weather data. Please try again later.',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Weather.fromJson(data);
    } catch (e) {
      throw Exception(
        'An unexpected error occurred. Please try again later.',
      );
    }
  }
}
