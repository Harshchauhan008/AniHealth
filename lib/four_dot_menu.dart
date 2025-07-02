import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wufcare/login_in.dart';
import 'package:wufcare/history_screen.dart';

class FourDotMenu extends StatelessWidget {
  final VoidCallback onClose;
  final String collarId;
  final Map<String, dynamic> profileData;

  const FourDotMenu({
    super.key,
    required this.onClose,
    required this.collarId,
    required this.profileData,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.history_outlined, color: Colors.grey),
                title: const Text("History"),
                onTap: () {
                  onClose();
                  Future.delayed(Duration.zero, () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            HistoryScreen(
                              lastId: collarId,
                              profileData: profileData,
                            ),
                      ),
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.grey),
                title: const Text('Logout'),
                onTap: () {
                  final navigator = Navigator.of(context);
                  onClose(); // Close the menu first
                  Future.delayed(Duration.zero, () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('collar_id');
                    navigator.pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  });
                },
              ),


            ],
          ),
        ),
      ),
    );
  }
}
