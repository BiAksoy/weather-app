class Weather {
  Weather({
    required this.city,
    required this.currentWeather,
    required this.hourlyForecasts,
  });

  factory Weather.fromJson(Map<String, dynamic> data) {
    final city = City.fromJson(data['city'] as Map<String, dynamic>);
    final currentWeather =
        CurrentWeather.fromJson(data['list'][0] as Map<String, dynamic>);
    final hourlyForecasts = List<HourlyForecast>.from(
      (data['list'] as List).map((hourlyForecast) {
        return HourlyForecast.fromJson(hourlyForecast as Map<String, dynamic>);
      }),
    );

    return Weather(
      city: city,
      currentWeather: currentWeather,
      hourlyForecasts: hourlyForecasts,
    );
  }
  final City city;
  final CurrentWeather currentWeather;
  final List<HourlyForecast> hourlyForecasts;
}

class CurrentWeather {
  CurrentWeather({
    required this.time,
    required this.temperature,
    required this.sky,
    required this.skyDescription,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> data) {
    final time =
        DateTime.fromMillisecondsSinceEpoch((data['dt'] as int) * 1000).toUtc();
    final temperature = data['main']['temp'] as double;
    final sky = data['weather'][0]['main'] as String;
    final skyDescription = data['weather'][0]['description'] as String;
    final humidity = data['main']['humidity'] as int;
    // Convert the wind speed from m/s to km/h.
    final windSpeed = (data['wind']['speed'] as double) * 3.6;
    final pressure = data['main']['pressure'] as int;

    return CurrentWeather(
      time: time,
      temperature: temperature,
      sky: sky,
      skyDescription: skyDescription,
      humidity: humidity,
      windSpeed: windSpeed,
      pressure: pressure,
    );
  }
  final DateTime time;
  final double temperature;
  final String sky;
  final String skyDescription;
  final int humidity;
  final double windSpeed;
  final int pressure;
}

class HourlyForecast {
  HourlyForecast({
    required this.time,
    required this.sky,
    required this.temperature,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> data) {
    final time =
        DateTime.fromMillisecondsSinceEpoch((data['dt'] as int) * 1000).toUtc();
    final sky = data['weather'][0]['main'] as String;
    final temperature = data['main']['temp'].toDouble() as num;

    return HourlyForecast(
      time: time,
      sky: sky,
      temperature: temperature,
    );
  }
  final DateTime time;
  final String sky;
  final num temperature;
}

class City {
  City({
    required this.name,
    required this.timezone,
    required this.sunriseTime,
    required this.sunsetTime,
  });

  factory City.fromJson(Map<String, dynamic> data) {
    final name = data['name'] as String;
    final timezone = data['timezone'] as int;
    final sunriseTime =
        DateTime.fromMillisecondsSinceEpoch((data['sunrise'] as int) * 1000)
            .toUtc()
            .add(Duration(seconds: timezone));
    final sunsetTime =
        DateTime.fromMillisecondsSinceEpoch((data['sunset'] as int) * 1000)
            .toUtc()
            .add(Duration(seconds: timezone));

    return City(
      name: name,
      timezone: timezone,
      sunriseTime: sunriseTime,
      sunsetTime: sunsetTime,
    );
  }
  final String name;
  final int timezone;
  final DateTime sunriseTime;
  final DateTime sunsetTime;
}
