import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wufcare/login_in.dart';
import 'package:wufcare/main.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController collarIdController = TextEditingController();

  List<String> collarList = [];

  @override
  void initState() {
    super.initState();
    loadSavedCollars();
  }

  Future<void> loadSavedCollars() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('collar_list') ?? [];
    setState(() {
      collarList = list;
    });
  }

  Future<void> loginOrCreateProfile() async {
    final name = nameController.text.trim();
    final collarId = collarIdController.text.trim();

    if (name.isEmpty || collarId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both name and collar ID")),
      );
      return;
    }

    final dbRef = FirebaseDatabase.instance.ref('dog_profile/$collarId');
    final snapshot = await dbRef.get();

    final profileData = {
      'name': name,
      'collar': collarId,
    };

    // If profile already exists, check name match (simulate login)
    if (snapshot.exists) {
      final existingData = Map<String, dynamic>.from(snapshot.value as Map);
      if (existingData['name'] != name) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wrong name for this collar ID")),
        );
        return;
      }
    } else {
      // If not exists, create new profile
      await dbRef.set(profileData);
    }

    // Save to shared prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('collar_id');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));


    final existingList = prefs.getStringList('collar_list') ?? [];
    if (!existingList.contains(collarId)) {
      existingList.add(collarId);
      await prefs.setStringList('collar_list', existingList);
    }

    if (!mounted) return;

    final profileSnapshot = await FirebaseDatabase.instance.ref('dog_profile/$collarId').get();
    final profileMap = Map<String, dynamic>.from(profileSnapshot.value as Map);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MyHomePage(
          title: 'AniHealth',
          collarId: collarId,
          profileData: profileMap,
        ),
      ),
    );

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add or Switch Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: collarIdController,
              decoration: const InputDecoration(labelText: 'Collar ID'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginOrCreateProfile,
              child: const Text('Create Profile'),
            ),
            const Divider(height: 40),
            const Text('Previously Used Profiles', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: collarList.length,
                itemBuilder: (context, index) {
                  final id = collarList[index];
                  return ListTile(
                    title: Text('Collar ID: $id'),
                    onTap: () async {
                      Navigator.pop(context);

                      final snapshot = await FirebaseDatabase.instance.ref('dog_profile/$id').get();
                      if (!snapshot.exists) return;

                      final profileMap = Map<String, dynamic>.from(snapshot.value as Map);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyHomePage(
                            title: 'AniHealth',
                            collarId: id,
                            profileData: profileMap,
                          ),
                        ),
                      );
                    },

                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SwitchCollarDialog extends StatelessWidget {
  const SwitchCollarDialog({super.key});

  Future<List<String>> _getCollarList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('collar_list') ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Switch Collar'),
      content: FutureBuilder<List<String>>(
        future: _getCollarList(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          final collarList = snapshot.data!;
          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: collarList.length,
              itemBuilder: (context, index) {
                final id = collarList[index];
                return ListTile(
                  title: Text('Collar: $id'),
                  onTap: () async {
                    Navigator.pop(context);

                    final snapshot = await FirebaseDatabase.instance
                        .ref('dog_profile/$id')
                        .get();

                    if (!snapshot.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("No profile found for $id")),
                      );
                      return;
                    }

                    final profileMap = Map<String, dynamic>.from(snapshot.value as Map);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyHomePage(
                          title: 'AniHealth',
                          collarId: id,
                          profileData: profileMap,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
