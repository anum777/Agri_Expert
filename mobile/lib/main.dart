import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/firebase_service.dart';
import 'services/crop_prediction_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agri Expert',
      theme: ThemeData(primarySwatch: Colors.green),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return DashboardScreen();
        }
        return AuthScreen();
      },
    );
  }
}

// ============= AUTH SCREEN =============
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showOTPInput = false;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _verificationId = '';
  bool _isLoading = false;
  String _message = '';

  void _sendOTP() async {
    setState(() => _isLoading = true);
    String phone = '+91' + _phoneController.text.trim();

    await FirebaseService().verifyPhoneNumber(
      phone,
      (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _showOTPInput = true;
          _isLoading = false;
          _message = 'OTP sent to ${_phoneController.text}';
        });
      },
      (errorMessage) {
        setState(() {
          _isLoading = false;
          _message = errorMessage;
        });
      },
    );
  }

  void _verifyOTP() async {
    setState(() => _isLoading = true);
    String otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      setState(() {
        _isLoading = false;
        _message = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    UserCredential? result =
        await FirebaseService().signInWithOTP(_verificationId, otp);
    setState(() {
      _isLoading = false;
      _message = result != null
          ? 'Login successful!'
          : 'Invalid OTP. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agri Expert - Login'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40),
              Icon(Icons.agriculture, size: 80, color: Colors.green),
              SizedBox(height: 20),
              Text(
                'Smart Crop Advisory',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              if (!_showOTPInput) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number (10 digits)',
                    prefixText: '+91 ',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 10,
                ),
                SizedBox(height: 16),
                if (_message.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(_message,
                        style:
                            TextStyle(color: Colors.orange[900], fontSize: 14)),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Send OTP'),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '6-digit OTP',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 6,
                ),
                SizedBox(height: 16),
                if (_message.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(_message,
                        style:
                            TextStyle(color: Colors.orange[900], fontSize: 14)),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Verify OTP'),
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showOTPInput = false;
                      _message = '';
                      _phoneController.clear();
                      _otpController.clear();
                    });
                  },
                  child: Text('Back'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============= DASHBOARD SCREEN =============
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _logout() async {
    await FirebaseService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agri Expert Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 100, color: Colors.green),
            SizedBox(height: 32),
            Text(
              'Welcome to Agri Expert',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Get smart crop recommendations',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 64),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationWeatherScreen(),
                  ),
                );
              },
              icon: Icon(Icons.location_on),
              label: Text('Get Location & Weather'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= LOCATION & WEATHER SCREEN =============
class LocationWeatherScreen extends StatefulWidget {
  @override
  _LocationWeatherScreenState createState() => _LocationWeatherScreenState();
}

class _LocationWeatherScreenState extends State<LocationWeatherScreen> {
  bool _isLoadingLocation = false;
  bool _isLoadingWeather = false;

  double? _latitude;
  double? _longitude;
  String _locationName = 'Tap to get location';

  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationName =
            'Lat: ${_latitude?.toStringAsFixed(4)}, Lon: ${_longitude?.toStringAsFixed(4)}';
      });

      await _getWeather();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getWeather() async {
    if (_latitude == null || _longitude == null) return;

    setState(() => _isLoadingWeather = true);
    try {
      const apiKey = '8704f35507dd49dd0c44bdb7efec8fb3';
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$_latitude&lon=$_longitude&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Weather error: $e')));
    } finally {
      setState(() => _isLoadingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location'),
        backgroundColor: Color(0xFFB8956A),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            // Location Card
            Card(
              color: Color(0xFFE8E0D5),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.location_on, size: 50, color: Color(0xFFB8956A)),
                    SizedBox(height: 12),
                    Text(
                      _locationName,
                      style: TextStyle(
                          color: Color(0xFF5C3D2E),
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoadingLocation ? null : _getLocation,
                      child: _isLoadingLocation
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Get Location'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Weather Card
            if (_weatherData != null) ...[
              Card(
                color: Color(0xFFD4B5A0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        _weatherData?['weather']?[0]?['main'] ?? 'Unknown',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C3D2E)),
                      ),
                      Text(
                        _weatherData?['weather']?[0]?['description'] ?? '',
                        style: TextStyle(color: Color(0xFF8B6F47)),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.thermostat_outlined,
                                  color: Color(0xFF5C3D2E), size: 28),
                              SizedBox(height: 6),
                              Text(
                                '${_weatherData?['main']?['temp']?.toStringAsFixed(1) ?? '--'}°C',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5C3D2E)),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.opacity_outlined,
                                  color: Color(0xFF5C3D2E), size: 28),
                              SizedBox(height: 6),
                              Text(
                                '${_weatherData?['main']?['humidity']?.toString() ?? '--'}%',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5C3D2E)),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.air_outlined,
                                  color: Color(0xFF5C3D2E), size: 28),
                              SizedBox(height: 6),
                              Text(
                                '${_weatherData?['wind']?['speed']?.toStringAsFixed(2) ?? '--'} m/s',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5C3D2E)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.speed_outlined,
                                  color: Color(0xFF5C3D2E), size: 24),
                              SizedBox(height: 4),
                              Text(
                                '${_weatherData?['main']?['pressure']?.toString() ?? '--'} hPa',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5C3D2E)),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.visibility_outlined,
                                  color: Color(0xFF5C3D2E), size: 24),
                              SizedBox(height: 4),
                              Text(
                                '${((_weatherData?['visibility'] as num?) ?? 10000).toInt() ~/ 1000} km',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5C3D2E)),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.cloud_outlined,
                                  color: Color(0xFF5C3D2E), size: 24),
                              SizedBox(height: 4),
                              Text(
                                '${_weatherData?['clouds']?['all']?.toString() ?? '--'}%',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5C3D2E)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_weatherData?['sys']?['country'] != null) ...[
                        SizedBox(height: 14),
                        Divider(color: Color(0xFF8B6F47)),
                        SizedBox(height: 14),
                        Text(
                          'Location: ${_weatherData?['name']}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5C3D2E),
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CropPredictionScreen(weatherData: _weatherData!),
                    ),
                  );
                },
                icon: Icon(Icons.arrow_forward),
                label: Text('Get Crop Recommendation'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============= CROP PREDICTION SCREEN =============
class CropPredictionScreen extends StatefulWidget {
  final Map<String, dynamic> weatherData;

  CropPredictionScreen({required this.weatherData});

  @override
  _CropPredictionScreenState createState() => _CropPredictionScreenState();
}

class _CropPredictionScreenState extends State<CropPredictionScreen> {
  final _nitrogenController = TextEditingController(text: '50');
  final _phosphorusController = TextEditingController(text: '40');
  final _potassiumController = TextEditingController(text: '30');

  bool _isPredicting = false;
  String _recommendedCrop = '';
  double _confidence = 0;
  String _reasoning = '';
  Map<String, dynamic>? _inputSummary;

  Future<void> _getPrediction() async {
    setState(() => _isPredicting = true);

    try {
      final nitrogen = double.parse(_nitrogenController.text);
      final phosphorus = double.parse(_phosphorusController.text);
      final potassium = double.parse(_potassiumController.text);

      final temperature =
          (widget.weatherData['main']?['temp'] ?? 25).toDouble();
      final humidity =
          (widget.weatherData['main']?['humidity'] ?? 80).toDouble();
      final rainfall = (widget.weatherData['clouds']?['all'] ?? 200).toDouble();

      final result = await CropPredictionService.predictCrop(
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        temperature: temperature,
        humidity: humidity,
        rainfall: rainfall,
      );

      setState(() {
        _recommendedCrop = result?['recommended_crop'] ?? 'Unknown';
        _confidence = result?['confidence'] ?? 0;
        _reasoning = result?['reasoning'] ?? '';
        _inputSummary = result?['input_summary'] ?? {};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recommended: $_recommendedCrop (${(_confidence * 100).toStringAsFixed(1)}%)',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isPredicting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Recommendation'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 12),
            // NPK Input Section
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NPK Values (mg/kg)',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nitrogenController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: 'Nitrogen (N)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.eco)),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _phosphorusController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: 'Phosphorus (P)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.eco)),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _potassiumController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: 'Potassium (K)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.eco)),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Prediction Button
            ElevatedButton.icon(
              onPressed: _isPredicting ? null : _getPrediction,
              icon: Icon(Icons.psychology),
              label: _isPredicting
                  ? Text('Analyzing...')
                  : Text('Get Crop Recommendation'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),

            // Result Card
            if (_recommendedCrop.isNotEmpty) ...[
              SizedBox(height: 32),
              Card(
                color: Colors.green[50],
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 48),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recommended Crop',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _recommendedCrop,
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[900]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Confidence Badge
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confidence Level',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _confidence,
                                      minHeight: 8,
                                      backgroundColor: Colors.green[100],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.green),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  '${(_confidence * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[900]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Reasoning Section
                      if (_reasoning.isNotEmpty) ...[
                        Text(
                          'Why This Crop?',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[900]),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _reasoning,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[800],
                              height: 1.6,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                      // Input Summary
                      if (_inputSummary != null &&
                          _inputSummary!.isNotEmpty) ...[
                        Text(
                          'Analysis Parameters',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[900]),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow('N (Nitrogen)',
                                  '${_inputSummary?['nitrogen']?.toStringAsFixed(1) ?? '-'} mg/kg'),
                              _buildSummaryRow('P (Phosphorus)',
                                  '${_inputSummary?['phosphorus']?.toStringAsFixed(1) ?? '-'} mg/kg'),
                              _buildSummaryRow('K (Potassium)',
                                  '${_inputSummary?['potassium']?.toStringAsFixed(1) ?? '-'} mg/kg'),
                              Divider(),
                              _buildSummaryRow('Temperature',
                                  '${_inputSummary?['temperature']?.toStringAsFixed(1) ?? '-'}°C'),
                              _buildSummaryRow('Humidity',
                                  '${_inputSummary?['humidity']?.toStringAsFixed(0) ?? '-'}%'),
                              _buildSummaryRow('Rainfall',
                                  '${_inputSummary?['rainfall']?.toStringAsFixed(1) ?? '-'} mm'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    super.dispose();
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[900],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
