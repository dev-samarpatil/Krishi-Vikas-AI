/// Weather model containing current conditions and a 5-day forecast.
class WeatherModel {
  final double temp;
  final String condition;
  final int humidity;
  final double windSpeed;
  final List<ForecastModel> forecast;
  final String? alert;

  const WeatherModel({
    required this.temp,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.forecast,
    this.alert,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temp: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'] as String,
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      forecast: [], // Will be parsed separately if from combined API response
      alert: null,
    );
  }
}

class ForecastModel {
  final DateTime date;
  final double temp;
  final String condition;

  const ForecastModel({
    required this.date,
    required this.temp,
    required this.condition,
  });
}
