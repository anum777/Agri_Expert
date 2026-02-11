import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'services/firebase_service.dart';
import 'services/weather_service.dart';
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

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  String _verificationId = '';
  bool _showOTPInput = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    setState(() => _isLoading = true);
    String phoneNumber = _phoneController.text.trim();
    
    if (phoneNumber.isEmpty) {
      setState(() {
        _isLoading = false;
        _message = 'Please enter a phone number';
      });
      return;
    }

    // Format phone number with country code if not present
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+91$phoneNumber'; // Default to India
    }

    FirebaseService().verifyPhoneNumber(
      phoneNumber,
      (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _showOTPInput = true;
          _isLoading = false;
          _message = 'OTP sent to $phoneNumber';
        });
      },
      (error) {
        setState(() {
          _isLoading = false;
          _message = error;
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

    UserCredential? result = await FirebaseService().signInWithOTP(_verificationId, otp);
    setState(() {
      _isLoading = false;
      _message = result != null ? 'Login successful!' : 'Invalid OTP. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agri Expert - Farmer Login'),
        elevation: 0,
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
              SizedBox(height: 8),
              Text(
                'Get personalized crop recommendations',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 40),
              if (!_showOTPInput) ...[
                Text('Enter Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number (10 digits)',
                    prefixText: '+91 ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: '9876543210',
                  ),
                  maxLength: 10,
                ),
                SizedBox(height: 16),
                if (_message.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                      child: Text(_message, style: TextStyle(color: Colors.orange[900], fontSize: 14)),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ] else ...[
                Text('Enter OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text('We sent a 6-digit code to +91${_phoneController.text}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: '000000',
                  ),
                ),
                SizedBox(height: 16),
                if (_message.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                      child: Text(_message, style: TextStyle(color: Colors.orange[900], fontSize: 14)),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() => _showOTPInput = false),
                  child: Text('Change Phone Number'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseService().signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Agri Expert', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationScreen())),
              child: Text('Start Crop Recommendation'),
            )
          ],
        ),
      ),
    );
  }
}

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _position;
  String _status = 'Press the button to get location';
  Map<String, dynamic>? _weather;
  String _weatherStatus = '';

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = 'Location services disabled');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _status = 'Location permission denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _status = 'Location permission permanently denied');
      return;
    }
    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      _position = pos;
      _status = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lon: ${pos.longitude.toStringAsFixed(4)}';
    });
    // Fetch weather after getting location
    final weatherService = WeatherService('8704f35507dd49dd0c44bdb7efec8fb3');
    final weather = await weatherService.fetchWeather(pos.latitude, pos.longitude);
    setState(() {
      _weather = weather;
      _weatherStatus = weather != null
          ? 'Temp: ${weather['main']['temp']}°C, Humidity: ${weather['main']['humidity']}%'
          : 'Weather fetch failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location'),
        backgroundColor: Color(0xFF795548), // Earth-tone brown
      ),
      backgroundColor: Color(0xFFF5E9E2), // Light earth background
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                color: Color(0xFFD7CCC8), // Muted brown
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 48, color: Color(0xFF6D4C41)),
                      SizedBox(height: 8),
                      Text(_status, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Color(0xFF6D4C41))),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _getLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8D6E63),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Get Location', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              if (_weather != null)
                Card(
                  color: Color(0xFFBCAAA4), // Earth-tone weather card
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud, size: 40, color: Color(0xFF6D4C41)),
                            SizedBox(width: 12),
                            Text('${_weather?['weather'][0]['main']}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6D4C41))),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('${_weather?['weather'][0]['description']}', style: TextStyle(fontSize: 16, color: Color(0xFF6D4C41))),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.thermostat, color: Color(0xFF6D4C41)),
                                Text('${_weather?['main']['temp']}°C', style: TextStyle(fontSize: 18, color: Color(0xFF6D4C41))),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.water_drop, color: Color(0xFF6D4C41)),
                                Text('Humidity: ${_weather?['main']['humidity']}%', style: TextStyle(fontSize: 18, color: Color(0xFF6D4C41))),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.air, color: Color(0xFF6D4C41)),
                                Text('Wind: ${_weather?['wind']['speed']} m/s', style: TextStyle(fontSize: 16, color: Color(0xFF6D4C41))),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.visibility, color: Color(0xFF6D4C41)),
                                Text('Visibility: ${_weather?['visibility']} m', style: TextStyle(fontSize: 16, color: Color(0xFF6D4C41))),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.compress, color: Color(0xFF6D4C41)),
                                Text('Pressure: ${_weather?['main']['pressure']} hPa', style: TextStyle(fontSize: 16, color: Color(0xFF6D4C41))),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.wb_sunny, color: Color(0xFF6D4C41)),
                                Text('Sunrise: ${DateTime.fromMillisecondsSinceEpoch((_weather?['sys']['sunrise'] ?? 0) * 1000).toLocal().hour}:${DateTime.fromMillisecondsSinceEpoch((_weather?['sys']['sunrise'] ?? 0) * 1000).toLocal().minute}', style: TextStyle(fontSize: 16, color: Color(0xFF6D4C41))),
                                Text('Sunset: ${DateTime.fromMillisecondsSinceEpoch((_weather?['sys']['sunset'] ?? 0) * 1000).toLocal().hour}:${DateTime.fromMillisecondsSinceEpoch((_weather?['sys']['sunset'] ?? 0) * 1000).toLocal().minute}', style: TextStyle(fontSize: 16, color: Color(0xFF6D4C41))),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.grain, color: Color(0xFF6D4C41)),
                            SizedBox(width: 8),
                            Builder(
                              builder: (context) {
                                String rainfallText = 'Rainfall: N/A';
                                final rainRaw = _weather != null ? _weather['rain'] : null;
                                if (rainRaw is Map) {
                                  final rain = Map<String, dynamic>.from(rainRaw);
                                  if (rain['1h'] != null) {
                                    rainfallText = 'Rainfall: ${rain['1h']} mm (last 1h)';
                                  } else if (rain['3h'] != null) {
                                    rainfallText = 'Rainfall: ${rain['3h']} mm (last 3h)';
                                  }
                                }
                                return Text(
                                  rainfallText,
                                  style: TextStyle(fontSize: 16, color: Color(0xFF6D4C41)),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('Location: ${_weather?['name']}', style: TextStyle(fontSize: 16, color: Color(0xFF6D4C41))),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _position != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SoilInputScreen(position: _position)),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8D6E63),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text('Proceed to Soil Input', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SoilInputScreen extends StatefulWidget {
  final Position? position;
  SoilInputScreen({this.position});

  @override
  _SoilInputScreenState createState() => _SoilInputScreenState();
}

class _SoilInputScreenState extends State<SoilInputScreen> {
  final _nitrogen = TextEditingController();
  final _phosphorus = TextEditingController();
  final _potassium = TextEditingController();
  final _ph = TextEditingController();

  @override
  void dispose() {
    _nitrogen.dispose();
    _phosphorus.dispose();
    _potassium.dispose();
    _ph.dispose();
    super.dispose();
  }

  void _submit() {
    Map<String, dynamic> payload = {
      'nitrogen': int.tryParse(_nitrogen.text) ?? 0,
      'phosphorus': int.tryParse(_phosphorus.text) ?? 0,
      'potassium': int.tryParse(_potassium.text) ?? 0,
      'ph': double.tryParse(_ph.text) ?? 7.0,
      'latitude': widget.position?.latitude ?? 0,
      'longitude': widget.position?.longitude ?? 0,
    };
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(payload: payload)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Soil Parameters')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _nitrogen, decoration: InputDecoration(labelText: 'Nitrogen (N)', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(controller: _phosphorus, decoration: InputDecoration(labelText: 'Phosphorus (P)', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(controller: _potassium, decoration: InputDecoration(labelText: 'Potassium (K)', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(controller: _ph, decoration: InputDecoration(labelText: 'Soil pH', border: OutlineInputBorder())),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text('Get Recommendation'))
          ],
        ),
      ),
    );
  }
}

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> payload;
  ResultScreen({required this.payload});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<void> _saveFuture;
  Map<String, dynamic>? _weather;
  String _weatherStatus = '';

  @override
  void initState() {
    super.initState();
    _saveFuture = FirebaseService().savePrediction({
      ...widget.payload,
      'recommended_crop': 'Rice',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recommendation')),
      body: FutureBuilder(
        future: _saveFuture,
        builder: (context, snapshot) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Recommended Crop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Text('Rice', style: TextStyle(fontSize: 32, color: Colors.green, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  if (snapshot.connectionState == ConnectionState.done)
                    Text('Saved to history.', style: TextStyle(color: Colors.grey))
                  else
                    CircularProgressIndicator(),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
                    child: Text('Back to Home'),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
