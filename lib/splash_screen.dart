import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wufcare/login_in.dart';
import 'package:wufcare/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString('collar_id');

    if (lastId != null) {
      final snapshot = await FirebaseDatabase.instance.ref('dog_profile/$lastId').get();
      if (snapshot.exists) {
        final profileMap = Map<String, dynamic>.from(snapshot.value as Map);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MyHomePage(
              title: 'AniHealth',
              collarId: lastId,             // ✅ Use retrieved collar ID
              profileData: profileMap,      // ✅ Use retrieved profile data
            ),
          ),
    );
        return;
      }
    }

    // No ID or not found -> Go to login
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset('assets/images/AniHealth_Logo.png'),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.only(top: 250, right: 50, left: 50),
              child: Text(
                'Their Safety, Health & Happiness',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'All In One Touch',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
