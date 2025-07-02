import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:wufcare/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _collarIdController = TextEditingController();
  bool _isLoading = false;
  List<String> _savedProfiles = [];

  @override
  void initState() {
    super.initState();
    _checkSavedCollar();
    _loadSavedProfiles();
  }

  Future<void> _checkSavedCollar() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('collar_id');

    if (savedId != null) {
      final snapshot = await FirebaseDatabase.instance.ref('dog_profile/$savedId').get();

      if (snapshot.exists) {
        final profileMap = Map<String, dynamic>.from(snapshot.value as Map);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MyHomePage(
              title: 'AniHealth',
              collarId: savedId,
              profileData: profileMap,
            ),
          ),
        );
      } else {
        await prefs.remove('collar_id');
      }
    }
  }

  Future<void> _loadSavedProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = prefs.getStringList('saved_profiles') ?? [];
    setState(() {
      _savedProfiles = profiles;
    });
  }

  Future<void> _saveProfile(String collarId) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = prefs.getStringList('saved_profiles') ?? [];
    if (!profiles.contains(collarId)) {
      profiles.add(collarId);
      await prefs.setStringList('saved_profiles', profiles);
    }
  }

  Future<void> _removeProfile(String collarId) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = prefs.getStringList('saved_profiles') ?? [];
    profiles.remove(collarId);
    await prefs.setStringList('saved_profiles', profiles);
    setState(() {
      _savedProfiles = profiles;
    });
  }

  Future<void> _login({String? overrideId}) async {
    setState(() => _isLoading = true);

    final lastId = overrideId ?? _collarIdController.text.trim();
    final snapshot = await FirebaseDatabase.instance.ref('dog_profile/$lastId').get();

    if (snapshot.exists) {
      final profileMap = Map<String, dynamic>.from(snapshot.value as Map);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('collar_id', lastId);
      await _saveProfile(lastId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MyHomePage(
            title: 'AniHealth',
            collarId: lastId,
            profileData: profileMap,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collar ID not found!')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _collarIdController,
              decoration: InputDecoration(
                labelText: 'Enter Collar ID',
                prefixIcon: const Icon(Icons.pets),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey
              ),
              onPressed: _isLoading ? null : () => _login(),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
            const SizedBox(height: 30),
            if (_savedProfiles.isNotEmpty) const Text("Saved Profiles:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._savedProfiles.map(
                  (id) => Card(
                child: ListTile(
                  title: Text(id),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeProfile(id),
                  ),
                  onTap: () => _login(overrideId: id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
