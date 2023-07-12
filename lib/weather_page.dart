import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather_app/additional_info_item.dart';
import 'package:weather_app/hourly_forecast_card.dart';
import 'package:weather_app/secrets.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({
    required this.position,
    super.key,
  });

  final Position position;

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late String cityName;
  late Future<Map<String, dynamic>> _weather;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  Future<Map<String, dynamic>> _getWeatherBySearch([String? city]) async {
    try {
      cityName = city!;
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&units=metric&APPID=$openWeatherAPIKey',
        ),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch weather data. Please try again later.',
        );
      }
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception(
        'An unexpected error occurred. Please try again later.',
      );
    }
  }

  Future<Map<String, dynamic>> _getWeatherByCurrentLocation() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${widget.position.latitude}&lon=${widget.position.longitude}&units=metric&APPID=$openWeatherAPIKey',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch weather data. Please try again later.',
        );
      }
      final data = jsonDecode(response.body);
      setState(() {
        cityName = data['city']['name'];
        _weather = Future.value(data);
      });
      return _weather;
    } catch (e) {
      throw Exception(
        'An unexpected error occurred. Please try again later.',
      );
    }
  }

  IconData _getIconBySky(
      String sky, DateTime sunrise, DateTime sunset, DateTime current) {
    sunrise = sunrise.toLocal();
    sunset = sunset.toLocal();
    current = current.toLocal();
    final isDayTime =
        current.hour >= sunrise.hour && current.hour < sunset.hour;
    if (isDayTime) {
      switch (sky) {
        case 'Thunderstorm':
          return WeatherIcons.day_thunderstorm;
        case 'Drizzle':
          return WeatherIcons.day_showers;
        case 'Rain':
          return WeatherIcons.day_rain;
        case 'Snow':
          return WeatherIcons.day_snow;
        case 'Mist':
        case 'Smoke':
        case 'Haze':
        case 'Dust':
        case 'Fog':
        case 'Sand':
        case 'Ash':
        case 'Squall':
        case 'Tornado':
          return WeatherIcons.day_fog;
        case 'Clear':
          return WeatherIcons.day_sunny;
        case 'Clouds':
          return WeatherIcons.day_cloudy;
        default:
          return WeatherIcons.alien;
      }
    } else {
      switch (sky) {
        case 'Thunderstorm':
          return WeatherIcons.night_alt_thunderstorm;
        case 'Drizzle':
          return WeatherIcons.night_alt_showers;
        case 'Rain':
          return WeatherIcons.night_alt_rain;
        case 'Snow':
          return WeatherIcons.night_alt_snow;
        case 'Mist':
        case 'Smoke':
        case 'Haze':
        case 'Dust':
        case 'Fog':
        case 'Sand':
        case 'Ash':
        case 'Squall':
        case 'Tornado':
          return WeatherIcons.night_fog;
        case 'Clear':
          return WeatherIcons.night_clear;
        case 'Clouds':
          return WeatherIcons.night_alt_cloudy;
        default:
          return WeatherIcons.alien;
      }
    }
  }

  @override
  void initState() {
    _weather = _getWeatherByCurrentLocation();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _weather = _getWeatherByCurrentLocation();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                _searchFocusNode.unfocus();
                setState(() {
                  _weather = _getWeatherBySearch(value);
                });
                _searchController.clear();
              },
              decoration: InputDecoration(
                hintText: 'Search city',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _searchFocusNode.unfocus();
                    setState(() {
                      _weather = _getWeatherBySearch(_searchController.text);
                    });
                    _searchController.clear();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: FutureBuilder(
          future: _weather,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator.adaptive(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }
            final data = snapshot.data!;
            final currentWeatherData = data['list'][0];
            var currentTemperature = currentWeatherData['main']['temp'];
            currentTemperature =
                currentTemperature.toStringAsFixed(0); // no decimal after comma
            final currentSky = currentWeatherData['weather'][0]['main'];
            final currentSkyDescription =
                currentWeatherData['weather'][0]['description'];
            final currentHumidity = currentWeatherData['main']['humidity'];
            var currentWindSpeed = currentWeatherData['wind']['speed'];
            currentWindSpeed = currentWindSpeed * 3.6; // m/s to km/h
            currentWindSpeed =
                currentWindSpeed.toStringAsFixed(0); // no decimal after comma
            final currentPressure = currentWeatherData['main']['pressure'];
            final sunriseTime = DateTime.fromMillisecondsSinceEpoch(
                data['city']['sunrise'] * 1000);
            final sunsetTime = DateTime.fromMillisecondsSinceEpoch(
                data['city']['sunset'] * 1000);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  cityName,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                Text(
                                  '$currentTemperature°C',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  _getIconBySky(
                                    currentSky,
                                    sunriseTime,
                                    sunsetTime,
                                    DateTime.now(),
                                  ),
                                  size: 64,
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  currentSkyDescription,
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hourly Forecast',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        final hourlyForecast = data['list'][index + 1];
                        final hourlySky = hourlyForecast['weather'][0]['main'];
                        var hourlyTemperature = hourlyForecast['main']['temp'];
                        hourlyTemperature = hourlyTemperature
                            .toStringAsFixed(0); // no decimal after comma
                        final time = DateTime.parse(hourlyForecast['dt_txt']);

                        return HourlyForecastCard(
                          time: DateFormat.H().format(time),
                          icon: _getIconBySky(
                            hourlySky,
                            sunriseTime,
                            sunsetTime,
                            time,
                          ),
                          temperature: hourlyTemperature.toString(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          AdditionalInfoItem(
                            icon: WeatherIcons.humidity,
                            label: 'Humidity',
                            value: '$currentHumidity%',
                          ),
                          AdditionalInfoItem(
                            icon: WeatherIcons.wind,
                            label: 'Wind Speed',
                            value: '$currentWindSpeed km/h',
                          ),
                          AdditionalInfoItem(
                            icon: WeatherIcons.barometer,
                            label: 'Pressure',
                            value: '$currentPressure hPa',
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          AdditionalInfoItem(
                            icon: WeatherIcons.sunrise,
                            label: 'Sunrise',
                            value:
                                DateFormat.Hm().format(sunriseTime).toString(),
                          ),
                          AdditionalInfoItem(
                            icon: WeatherIcons.sunset,
                            label: 'Sunset',
                            value:
                                DateFormat.Hm().format(sunsetTime).toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
