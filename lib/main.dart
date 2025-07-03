
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:wufcare/firebase_options.dart';
import 'package:wufcare/four_dot_menu.dart';
import 'package:wufcare/heart__rate_graph.dart';
import 'package:wufcare/profile.dart';
import 'package:wufcare/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use the generated options
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String collarId;
  final Map<String, dynamic> profileData;

  final dynamic title;

  const MyHomePage({super.key, required this.title, required this.collarId, required this.profileData});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}



class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        titleSpacing: 0, // Remove default left padding
        title: Row(
          children: [
            const SizedBox(width: 10),
        ProfileBtn(collarId: widget.collarId), // 👈 now on the left
          ],
        ),
        actions: [
          FourDot(
            collarId: widget.collarId,
            profileData: widget.profileData,
          ),
        ],
      ),
      backgroundColor: Colors.blueGrey.withAlpha(178),
      body: Stack(
        children: [
          ToggleTabBar(profileData: widget.profileData),
          Temperature(collarId: widget.collarId),
          MidLevel(collarId: widget.collarId),
          HeartBit(collarId: widget.collarId),
        ],
      ),

    );
  }
}


class Temperature extends StatefulWidget {
  final String collarId;
  const Temperature({super.key, required this.collarId});

  @override
  State<Temperature> createState() => _TemperatureState();
}

class _TemperatureState extends State<Temperature> {
  late TimeOfDay _currentTime;
  String _day = 'Loading...';
  int _temperature = 0;
  int _humidity = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _fetchWeatherFromFirebase();

    // Recheck day and time every minute
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    _currentTime = TimeOfDay.fromDateTime(now);

    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    setState(() {
      _day = weekdays[now.weekday - 1];
    });
  }

  Future<void> _fetchWeatherFromFirebase() async {
    final ref = FirebaseDatabase.instance.ref('dog_profile/${widget.collarId}/weather');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _temperature = data['temperature'] ?? 0;
        _humidity = data['humidity'] ?? 0;
      });
    }
  }

  bool _isDayTime() {
    final hour = _currentTime.hour;
    return hour >= 6 && hour < 18;
  }

  @override
  Widget build(BuildContext context) {
    final isDay = _isDayTime();

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70),
        child: Container(
          height: 200,
          width: 350,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDay
                  ? [const Color(0xFFF8F9FA), const Color(0xFF007BFF)]
                  : [const Color(0xFF0F2027), const Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.8],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isDay ? Icons.wb_sunny : Icons.nightlight_round,
                    size: 100,
                    color: isDay ? Colors.orangeAccent : Colors.indigoAccent,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      _day,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Right side
              Padding(
                padding: const EdgeInsets.only(top: 40, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Temperature',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$_temperature°C',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w100,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Humidity: $_humidity%',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ProfileBtn extends StatefulWidget {
  final String collarId;
  const ProfileBtn({super.key, required this.collarId});

  @override
  State<ProfileBtn> createState() => _ProfileBtnState();
}

class _ProfileBtnState extends State<ProfileBtn> {
  Map<String, String> profileData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final ref = FirebaseDatabase.instance.ref('dog_profile/${widget.collarId}');
    ref.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          profileData = data.map((key, value) => MapEntry(key, value.toString()));
          _isLoading = false;
        });
      } else {
        setState(() {
          profileData = {};
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _saveProfile(Map<String, String> updatedData) async {
    final dbRef = FirebaseDatabase.instance.ref('dog_profile/${widget.collarId}');
    await dbRef.set(updatedData);
    setState(() => profileData = updatedData);
  }

  void _openProfilePopup() async {
    final updated = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => ProfileDialog(
        profileData: profileData,
        onEdit: () async {
          final newData = await Navigator.push<Map<String, String>>(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(profileData: profileData),
            ),
          );
          if (newData != null) {
            await _saveProfile(newData);
            return newData;
          }
          return null;
        },
      ),
    );
    if (updated != null) {
      await _saveProfile(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : _openProfilePopup,
      child: Container(
        width: 150,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(60),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/Profile.png'),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: AnimatedOpacity(
                opacity: _isLoading ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isLoading ? 'Loading...' : (profileData['name'] ?? 'Name'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FourDot extends StatefulWidget {
  final String collarId;
  final Map<String, dynamic> profileData;

  const FourDot({
    super.key,
    required this.collarId,
    required this.profileData,
  });

  @override
  State<FourDot> createState() => _FourDotState();
}

class _FourDotState extends State<FourDot> {
  static OverlayEntry? _currentOverlay;

  void _toggleMenu(BuildContext context, Offset position) {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
      return;
    }

    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          overlayEntry?.remove();
          _currentOverlay = null;
        },
        child: Stack(
          children: [
            const SizedBox.expand(),
            Center(
              child: FourDotMenu(
                onClose: () {
                  overlayEntry?.remove();
                  _currentOverlay = null;
                },
                collarId: widget.collarId,
                profileData: widget.profileData,
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(overlayEntry);
    _currentOverlay = overlayEntry;
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTapDown: (details) {
            _toggleMenu(context, details.globalPosition);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.withAlpha(102),
            ),
            child: Image.asset('assets/images/four-circle.png'),
          ),
        );
      },
    );
  }
}


class MidLevel extends StatelessWidget {
  final String collarId;
  const MidLevel({super.key, required this.collarId});

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref('dog_profile/$collarId/health_data');

    return StreamBuilder<DatabaseEvent>(
      stream: databaseRef.onValue, // ✅ Corrected path
      builder: (context, snapshot) {
        final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;

        final spo2 = data?['spo2']?.toString() ?? '--';
        final bodyTemp = data?['body_temp']?.toString() ?? '--';

        return Stack(
          children: [
            Positioned(
              top: 300,
              left: 20,
              right: 20,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF9A825),
                      Color(0xFF4CB5AE),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.5],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      // SpO2 Box
                      Container(
                        padding: const EdgeInsets.all(10),
                        height: double.infinity,
                        width: 155,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF80CBC4),
                              Color(0xFF5C6BC0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.0, 0.8],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SpO2 %',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              '(Oxygen Level)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  spo2,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.water_drop,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Body Temp Box
                      Container(
                        padding: const EdgeInsets.all(10),
                        height: double.infinity,
                        width: 155,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.blueGrey,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Body',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Temperature',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  bodyTemp,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.thermostat,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
// Heart rate and Graph
class HeartBit extends StatelessWidget {
  final String collarId;
  const HeartBit({super.key, required this.collarId});

  @override
  Widget build(BuildContext context) {
    final dbRef = FirebaseDatabase.instance.ref('dog_profile/$collarId/heart_rate_data');

    return StreamBuilder<DatabaseEvent>(
      stream: dbRef.onValue,
      builder: (context, snapshot) {
        double currentRate = 0.0;
        List<double> history = [];

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value as Map;
          currentRate = data['live']?.toDouble() ?? 0.0;
          history = List<double>.from(
            (data['history'] as List).map((e) => (e as num).toDouble()),
          );
        }

        return Stack(
          children: [
            Positioned(
              top: 480,
              left: 20,
              right: 20,
              child: Container(
                height: 200,
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.pink],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    stops: [0.0, 0.7],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      // Graph
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: HeartRateGraph(heartRates: history),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Heart info
                      Container(
                        height: double.infinity,
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'Heart Rate',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(
                                height: 130,
                                width: 130,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                      size: 130,
                                    ),
                                    Text(
                                      currentRate > 0
                                          ? '$currentRate\nbpm'
                                          : '--\nbpm',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ToggleTabBar extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const ToggleTabBar({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    final String ownerName = profileData['owner'] ?? 'User'; // Use correct key

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, right: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Hello, $ownerName',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
