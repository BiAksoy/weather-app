import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/api/weather_api.dart';
import 'package:weather_app/model/weather_model.dart';
import 'package:weather_app/widgets/additional_info_item.dart';
import 'package:weather_app/widgets/hourly_forecast_card.dart';
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
  late Future<Weather> _weather;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  final WeatherAPI _weatherAPI = WeatherAPI();

  @override
  void initState() {
    _weather = _weatherAPI.getWeatherByCurrentPosition(widget.position);
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
                _weather =
                    _weatherAPI.getWeatherByCurrentPosition(widget.position);
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
              onSubmitted: (cityName) {
                _searchFocusNode.unfocus();
                setState(() {
                  if (_searchController.text.isEmpty) {
                    return;
                  }
                  _weather = _weatherAPI.getWeatherBySearchedLocation(cityName);
                });
                _searchController.clear();
              },
              decoration: InputDecoration(
                hintText: 'Search Location',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _searchFocusNode.unfocus();
                    setState(() {
                      if (_searchController.text.isEmpty) {
                        return;
                      }
                      _weather = _weatherAPI
                          .getWeatherBySearchedLocation(_searchController.text);
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
        child: FutureBuilder<Weather>(
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
            final weather = snapshot.data!;
            final current = weather.currentWeather;
            final city = weather.city;

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
                                  city.name,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                Text(
                                  '${current.temperature.round()}°C',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  _getIconBySky(
                                    current.sky,
                                    city.sunriseTime,
                                    city.sunsetTime,
                                    current.time.add(
                                      Duration(seconds: city.timezone),
                                    ),
                                  ),
                                  size: 64,
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  current.skyDescription,
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
                        final forecast = weather.hourlyForecasts[index];

                        return HourlyForecastCard(
                          time: DateFormat.H().format(
                            forecast.time.add(
                              Duration(seconds: city.timezone),
                            ),
                          ),
                          icon: _getIconBySky(
                            forecast.sky,
                            city.sunriseTime,
                            city.sunsetTime,
                            forecast.time.add(
                              Duration(seconds: city.timezone),
                            ),
                          ),
                          temperature: forecast.temperature.round().toString(),
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
                            value: '${current.humidity}%',
                          ),
                          AdditionalInfoItem(
                            icon: WeatherIcons.wind,
                            label: 'Wind Speed',
                            value: '${current.windSpeed.round()} km/h',
                          ),
                          AdditionalInfoItem(
                            icon: WeatherIcons.barometer,
                            label: 'Pressure',
                            value: '${current.pressure} hPa',
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          AdditionalInfoItem(
                            icon: WeatherIcons.sunrise,
                            label: 'Sunrise',
                            value: DateFormat.Hm().format(city.sunriseTime),
                          ),
                          AdditionalInfoItem(
                            icon: WeatherIcons.sunset,
                            label: 'Sunset',
                            value: DateFormat.Hm().format(city.sunsetTime),
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

IconData _getIconBySky(
  String sky,
  DateTime sunrise,
  DateTime sunset,
  DateTime current,
) {
  final isDayTime = current.hour >= sunrise.hour && current.hour < sunset.hour;
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
