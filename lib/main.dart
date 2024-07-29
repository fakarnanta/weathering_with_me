import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather_icons/weather_icons.dart';
import 'package:open_meteo/open_meteo.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  runApp(const MyApp());
}

class WeatherData {
  final int dt;
  final double temp;
  final String description;
  final String iconCode;

  WeatherData({
    required this.dt,
    required this.temp,
    required this.description,
    required this.iconCode,
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = true; // State variable to track theme

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theme Switcher App',
      theme: _isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      home: HomePage(toggleTheme: _toggleTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function toggleTheme;

  const HomePage({super.key, required this.toggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String cityName = 'Loading...';
  double temperature = 0;
  String description = '';
  bool isLoading = true;
  String temperatureString = "";
  IconData weatherIcon = WeatherIcons.day_cloudy;
  String weatherMain = "";
  double feelsLike = 0;
  String feelsLikeString = "";
  List<WeatherData> hourlyData = [];
  double humidity = 0.0;
  String humidityString = '';
  double windSpeed = 0.0;
  String windString = '';
  double rainChance = 0.0;
  String rainChanceString = '';
  String uvChanceCategory = '';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  IconData mapWeatherToIcon(String weatherMain) {
    switch (weatherMain) {
      case 'Thunderstorm':
        return WeatherIcons.thunderstorm;
      case 'Drizzle':
      case 'Mist':
        return WeatherIcons.sleet;
      case 'Rain':
        return WeatherIcons.rain;
      case 'Snow':
        return WeatherIcons.snow;
      case 'Clear':
        return WeatherIcons.day_sunny;
      case 'Clouds':
        return WeatherIcons.cloudy;
      default:
        return WeatherIcons.na; // Not available icon
    }
  }

  String roundTemperature(double temp) {
    return temp.round().toString();
  }

  Future<void> _getLocation() async {
    Position position;
    final status = await Permission.location.request();

    if (status.isGranted) {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _fetchWeatherData(position.latitude, position.longitude);
      _fetchHourlyData(position.latitude, position.longitude);
      _fetchWeatherTemp('Malang');
      print("p");
    } else {
      print("jancokkk");
      // Check for both temporarily and permanently denied permissions
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Location permission is required to access this feature.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(), // Open app settings
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchHourlyData(double latitude, double longitude) async {
    // Replace with your actual API key
    const apiKey = '0df27df841f16f831b5b30b14d4672bf';

    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        isLoading = false;
        cityName = data['city']['name'];

        // Extract list of hourly data
        final hourlyList = data['list'] as List<dynamic>;

        // Update hourly data using a separate list or any preferred method
        hourlyData = hourlyList
            .map((hourData) => WeatherData(
                  dt: hourData['dt'],
                  temp: hourData['main']['temp'].toDouble(),
                  description: hourData['weather'][0]['description'],
                  iconCode: hourData['weather'][0]['main'],
                ))
            .toList();

        // ... Update other weather data as needed (temperature, description, etc.)
      });
    } else {
      print('Failed to fetch weather data');
      setState(() {
        isLoading = false;
        cityName = 'Failed to get weather data';
      });
    }
  }

  Future<void> _fetchWeatherData(double latitude, double longitude) async {
    // Replace with your API key
    const apiKey = '0df27df841f16f831b5b30b14d4672bf';

    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        isLoading = false;
        cityName = data['name'];
        temperature = data['main']['temp'];
        description = data['weather'][0]['description'];
        temperatureString = roundTemperature(temperature);
        weatherMain = data['weather'][0]['main'];
        feelsLike = data['main']['feels_like'];
        feelsLikeString = roundTemperature(feelsLike);
        weatherIcon = mapWeatherToIcon(weatherMain);
      });
    } else {
      print('Failed to get weather data');
      setState(() {
        isLoading = false;
        cityName = 'Failed to get weather data';
      });
    }
  }

  String _getGreetingText() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning!'; // Good morning
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon!'; // Good afternoon
    } else {
      return 'Good Evening!'; // Good evening
    }
  }

  String getUvIndexCategory(double uvIndex) {
    if (uvIndex <= 2.9) {
      return 'Low';
    } else if (uvIndex <= 5.9) {
      return 'Moderate';
    } else if (uvIndex <= 7.9) {
      return 'High';
    } else if (uvIndex <= 10.9) {
      return 'Very High';
    } else {
      return 'Extreme';
    }
  }

  Future<void> _fetchWeatherTemp(String city) async {
    final apiKey =
        '3ef6951e296a432895441305241507'; // Replace with your actual API key
    final url = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city&aqi=no');
    // Adjust the URL parameters based on their documentation

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        humidity = data['current']['humidity'].toDouble();
        humidityString = roundTemperature(humidity);
        windSpeed = data['current']['wind_kph'].toDouble();
        windString = roundTemperature(windSpeed);
        rainChance = data['current']['uv'].toDouble();
        rainChanceString = roundTemperature(rainChance);
        uvChanceCategory = getUvIndexCategory(rainChance);
        print("yolooooo");
      });
    } else {
      // Handle API errors
      throw Exception('Failed to load weather data');
    }
  }

  double getHumidity(Map<String, dynamic> data) {
    // Assuming humidity data is under 'current' -> 'humidity'
    return data['current']['humidity'].toDouble();
  }

  double getWindSpeed(Map<String, dynamic> data) {
    // Assuming wind speed data is under 'current' -> 'wind_kph'
    return data['current']['wind_kph'].toDouble();
  }

  double getChanceOfRain(Map<String, dynamic> data) {
    return data['current']['daily_chance_of_rain']; // Placeholder for now
  }

  @override
  Widget build(BuildContext context) {
    var weather = Weather(
        latitude: 52.52,
        longitude: 13.41,
        temperature_unit: TemperatureUnit.celsius);
    var hourly = [Hourly.temperature_2m];
    var result = weather.raw_request(hourly: hourly);
    print(result);
    return Scaffold(
      backgroundColor: Color(0xFF26355D),
      appBar: AppBar(
        backgroundColor: Color(0xFF26355D),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 37),
          child: Text(
            _getGreetingText(),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, top: 16, right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 1,
                height: 210,
                padding: EdgeInsets.symmetric(vertical: 30, horizontal: 30),
                decoration: BoxDecoration(
                    color: Color.fromARGB(69, 65, 88, 146).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(25)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Now',
                          style: GoogleFonts.plusJakartaSans(fontSize: 24),
                        ),
                        Row(
                          children: [
                            Icon(
                              Ionicons.location,
                              color: const Color.fromARGB(255, 238, 216, 23),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              cityName,
                              style: GoogleFonts.plusJakartaSans(fontSize: 10),
                            )
                          ],
                        )
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                    text: TextSpan(
                                        text: temperatureString,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold),
                                        children: <TextSpan>[
                                      TextSpan(
                                          text: '°C',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 24,
                                              color: const Color.fromARGB(
                                                  255, 238, 216, 23)))
                                    ])),
                                SizedBox(
                                  height: 9,
                                ),
                                Text(
                                  "Feels like $feelsLikeString°C",
                                  style: GoogleFonts.plusJakartaSans(),
                                )
                              ],
                            )
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            BoxedIcon(
                              weatherIcon,
                              size: 46,
                            ),
                            Text(
                              weatherMain,
                              style: GoogleFonts.plusJakartaSans(),
                            )
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                width: MediaQuery.of(context).size.width * 1,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Color.fromARGB(69, 65, 88, 146).withOpacity(0.4),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          BoxedIcon(
                            WeatherIcons.windy,
                            size: 30,
                          ),
                          Text(
                            '$windSpeed kph',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10),
                          ),
                          Text(
                            'Wind speed',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 8, color: Colors.grey[400]),
                          )
                        ],
                      ),
                      Container(
                        height: 25,
                        width: 1.25,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          BoxedIcon(
                            WeatherIcons.raindrops,
                            size: 30,
                          ),
                          Text(
                            '$humidityString %',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10),
                          ),
                          Text(
                            'Humidity',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 8, color: Colors.grey[400]),
                          )
                        ],
                      ),
                      Container(
                        height: 25,
                        width: 1.25,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          BoxedIcon(
                            WeatherIcons.hot,
                            size: 30,
                          ),
                          Text(
                            '$rainChance ($uvChanceCategory)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10),
                          ),
                          Text(
                            'UV Index',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 8, color: Colors.grey[400]),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Text(
                'Hourly cast',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(
                height: 20,
              ),
              HourlyWeatherList(hourlyData: hourlyData),
            ],
          ),
        ),
      ),
    );
  }
}

class HourlyWeatherList extends StatelessWidget {
  final List<WeatherData> hourlyData;

  String roundTemperature(double temp) {
    return temp.round().toString();
  }

  IconData mapWeatherToIcon(String weatherMain) {
    switch (weatherMain) {
      case 'Thunderstorm':
        return WeatherIcons.thunderstorm;
      case 'Drizzle':
      case 'Mist':
        return WeatherIcons.sleet;
      case 'Rain':
        return WeatherIcons.rain;
      case 'Snow':
        return WeatherIcons.snow;
      case 'Clear':
        return WeatherIcons.day_sunny;
      case 'Clouds':
        return WeatherIcons.cloudy;
      default:
        return WeatherIcons.na; // Not available icon
    }
  }

  const HourlyWeatherList({Key? key, required this.hourlyData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Set scroll direction to horizontal
        shrinkWrap: true, // Prevent excessive scrolling (optional)
        itemCount: hourlyData.length,
        itemBuilder: (context, index) {
          final hourData = hourlyData[index];
          final time =
              DateTime.fromMillisecondsSinceEpoch(hourData.dt * 1000).hour;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
                decoration: BoxDecoration(
                    color: Color.fromARGB(69, 65, 88, 146).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20)),
                // Customize container width and padding (optional)
                width: MediaQuery.of(context).size.width * 0.3, // Example width
                padding:
                    const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10),
                child: Stack(children: [
                  Positioned(
                      top: 5,
                      right: 5,
                      child: BoxedIcon(
                        mapWeatherToIcon(hourData.iconCode),
                        size: 36,
                      )),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$time:00',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        ),
                        RichText(
                            text: TextSpan(
                                text: roundTemperature(hourData.temp),
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                                children: <TextSpan>[
                              TextSpan(
                                  text: '°C',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: const Color.fromARGB(
                                          255, 238, 216, 23)))
                            ])),
                      ],
                    ),
                  ),
                ])),
          );
        },
      ),
    );
  }
}

//ListTile(
 //               title: Text('$time:00 - ${hourData.description}'),
 //               trailing: Text('${hourData.temp.toStringAsFixed(1)}°C'),
//              ),


