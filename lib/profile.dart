import 'dart:io';
import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDialog extends StatelessWidget {
  final Map<String, String> profileData;
  final Future<Map<String, String>?> Function() onEdit;

  const ProfileDialog({
    super.key,
    required this.profileData,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 150),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              Container(
                height: 400,
                width: 350,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8F9FA),Color(0xFF008080)],  // (Ghost White) and (Teal)
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0,0.9]
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Name: ${profileData['name'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Breed: ${profileData['breed'] ?? ''}'),
                              const SizedBox(height: 6),
                              Text('Gender: ${profileData['gender'] ?? ''}'),
                              const SizedBox(height: 6),
                              Text('DOB: ${profileData['dob'] ?? ''}'),
                              const SizedBox(height: 6),
                              Text('Age: ${profileData['age'] ?? ''}'),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/Profile.png',
                            width: 120,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Divider(thickness: 2, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text('Owner: ${profileData['owner'] ?? ''}'),
                    const SizedBox(height: 6),
                    Text('Contact: ${profileData['contact'] ?? ''}'),
                    const SizedBox(height: 6),
                    Text('Address: ${profileData['address'] ?? ''}'),
                    const SizedBox(height: 20),
                    Text(
                      'Collar Serial No.: ${profileData['collar'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00D4FF),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 220,
                right: 20,
                child: InkWell(
                  onTap: () async {
                    Navigator.of(context).pop(); // Close current dialog
                    await onEdit(); // Handle reopen from parent
                  },
                  child: const Icon(Icons.edit, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class EditProfileScreen extends StatefulWidget {
  final Map<String, String> profileData;

  const EditProfileScreen({super.key, required this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController breedController;
  late TextEditingController genderController;
  late TextEditingController dobController;
  late TextEditingController ageController;
  late TextEditingController ownerController;
  late TextEditingController contactController;
  late TextEditingController addressController;
  late TextEditingController collarController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profileData['name']);
    breedController = TextEditingController(text: widget.profileData['breed']);
    genderController = TextEditingController(text: widget.profileData['gender']);
    dobController = TextEditingController(text: widget.profileData['dob']);
    ageController = TextEditingController(text: widget.profileData['age']);
    ownerController = TextEditingController(text: widget.profileData['owner']);
    contactController = TextEditingController(text: widget.profileData['contact']);
    addressController = TextEditingController(text: widget.profileData['address']);
    collarController = TextEditingController(text: widget.profileData['collar']);
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    genderController.dispose();
    dobController.dispose();
    ageController.dispose();
    ownerController.dispose();
    contactController.dispose();
    addressController.dispose();
    collarController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() async {
    final updatedData = {
      'name': nameController.text.trim(),
      'breed': breedController.text.trim(),
      'gender': genderController.text.trim(),
      'dob': dobController.text.trim(),
      'age': ageController.text.trim(),
      'owner': ownerController.text.trim(),
      'contact': contactController.text.trim(),
      'address': addressController.text.trim(),
      'collar': collarController.text.trim(),
    };

    final collarId = updatedData['collar']!;
    if (collarId.isEmpty || updatedData['name']!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Collar Number are required.")),
      );
      return;
    }

    try {
      final dbRef = FirebaseDatabase.instance.ref('dog_profile/$collarId');
      await dbRef.set(updatedData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('collar_id', collarId);

      // Add collar ID to saved list
      final existingList = prefs.getStringList('collar_list') ?? [];
      if (!existingList.contains(collarId)) {
        existingList.add(collarId);
        await prefs.setStringList('collar_list', existingList);
      }
      final currentContext = context;
      if (!mounted) return;

// Return updated data instead of opening a dialog here
      Navigator.pop(context, updatedData); // ✅ returns the data back to caller


      // Wait a moment and then show the profile dialog
      await Future.delayed(const Duration(milliseconds: 100));

      showDialog(
        context: currentContext,
        builder: (_) => ProfileDialog(
          profileData: updatedData,
          onEdit: () async {
            Navigator.pop(currentContext); // ✅ Use stored context

            final result = await Navigator.push<Map<String, String>?>(
              currentContext,
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(profileData: updatedData),
              ),
            );

            return result ?? {}; // ✅ Always return something
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    }
  }


  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Edit Profile'),
      backgroundColor: Colors.white,),
    body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : const AssetImage('assets/images/Profile.png') as ImageProvider,
                    child: const Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField('Name', nameController),
                _buildTextField('Breed', breedController),
                _buildTextField('Gender', genderController),
                _buildTextField('DOB', dobController),
                _buildTextField('Age', ageController),
                _buildTextField('Owner Name', ownerController),
                _buildTextField('Contact', contactController),
                _buildTextField('Address', addressController),
                _buildTextField('Collar Serial No.', collarController),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,   // button background color
                    foregroundColor: Colors.white, // text color
                  ),
                  child:  Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
