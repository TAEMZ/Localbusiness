import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'pick_location_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BusinessForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSubmit;
  final Map<String, dynamic>? business; // Optional for editing

  const BusinessForm({super.key, this.onSubmit, this.business});

  @override
  _BusinessFormState createState() => _BusinessFormState();
}

class _BusinessFormState extends State<BusinessForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController openingController = TextEditingController();
  final TextEditingController closingController = TextEditingController();

  String? selectedCategory; // Dropdown value
  final List<String> categories = [
    'Restaurants',
    'Hairdresser',
    'Bars',
    'Delivery',
    'Coffee'
  ];

  File? _pickedImage;
  String? _uploadedImageUrl;
  LatLng? selectedLocation;
  bool _isLoading = false;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
    }

    if (widget.business != null) {
      nameController.text = widget.business!['name'] ?? '';
      descriptionController.text = widget.business!['description'] ?? '';
      phoneController.text = widget.business!['phone'] ?? '';
      cityController.text = widget.business!['city'] ?? '';
      openingController.text = widget.business!['opening_hours'] ?? '';
      closingController.text = widget.business!['closing_hours'] ?? '';
      selectedCategory = widget.business!['category'] ?? '';
      _uploadedImageUrl = widget.business!['image'] ?? '';

      if (widget.business!['location'] != null) {
        final loc = widget.business!['location'];
        selectedLocation = LatLng(loc['latitude'], loc['longitude']);
      }
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadImageToCloudinary() async {
    if (_pickedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cloudinaryUrl =
          Uri.parse('https://api.cloudinary.com/v1_1/da7hlicdz/image/upload');
      const uploadPreset = 'cloudinary'; // Replace with your preset
      const assetFolder = 'local_business_app';

      final request = http.MultipartRequest('POST', cloudinaryUrl)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = assetFolder
        ..files
            .add(await http.MultipartFile.fromPath('file', _pickedImage!.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        setState(() {
          _uploadedImageUrl = jsonResponse['secure_url'];
        });
      } else {
        throw Exception('Failed to upload image');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> pickLocation() async {
    const LatLng defaultLocation =
        LatLng(7.0262, 38.4408); // Default to Worabe, Ethiopia

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickLocationPage(
          initialLocation: selectedLocation ?? defaultLocation,
        ),
      ),
    );

    if (result != null && result is LatLng) {
      setState(() {
        selectedLocation = result;
      });
    }
  }

  Future<void> saveBusinessToFirestore(
      Map<String, dynamic> businessData) async {
    try {
      if (_uploadedImageUrl != null) {
        businessData['image'] = _uploadedImageUrl;
      }

      if (selectedLocation != null) {
        businessData['location'] = {
          'latitude': selectedLocation!.latitude,
          'longitude': selectedLocation!.longitude,
        };
      }

      // Add creatorId and email to the business data
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        businessData['creatorId'] = user.uid;
        businessData['creatorEmail'] = user.email;
      }

      await FirebaseFirestore.instance
          .collection('businesses')
          .add(businessData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to save business. Please try again.')),
      );
    }
  }

  void _validateAndSubmit() async {
    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        openingController.text.trim().isEmpty ||
        closingController.text.trim().isEmpty ||
        selectedCategory == null ||
        selectedCategory!.isEmpty ||
        (_pickedImage == null && _uploadedImageUrl == null) ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill in all fields, select an image, and pick a location.'),
        ),
      );
      return;
    }

    if (_pickedImage != null) {
      await uploadImageToCloudinary();
    }

    final businessData = {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'phone': phoneController.text.trim(),
      'city': cityController.text.trim(),
      'category': selectedCategory ?? '',
      'image': _uploadedImageUrl ?? '',
      'opening_hours': openingController.text.trim(),
      'closing_hours': closingController.text.trim(),
      'created_at': DateTime.now(),
    };

    await saveBusinessToFirestore(businessData);

    if (widget.onSubmit != null) {
      widget.onSubmit!(businessData);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.business == null
            ? localization.add_business
            : 'Edit Business'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                          labelText: localization.business_name),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          InputDecoration(labelText: localization.description),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration:
                          InputDecoration(labelText: localization.phone),
                    ),
                    TextField(
                      controller: cityController,
                      decoration: InputDecoration(labelText: localization.city),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration:
                          InputDecoration(labelText: localization.catagory),
                      items: categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _pickedImage != null
                        ? Image.file(_pickedImage!,
                            height: 150, fit: BoxFit.cover)
                        : (_uploadedImageUrl != null
                            ? Image.network(_uploadedImageUrl!,
                                height: 150, fit: BoxFit.cover)
                            : const Text('No image selected')),
                    TextButton(
                      onPressed: pickImage,
                      child: Text(localization.image),
                    ),
                    TextField(
                      controller: openingController,
                      decoration:
                          InputDecoration(labelText: localization.opening_hrs),
                    ),
                    TextField(
                      controller: closingController,
                      decoration:
                          InputDecoration(labelText: localization.closing_hrs),
                    ),
                    if (userEmail != null)
                      Text('Creator Email: $userEmail',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.blue)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: pickLocation,
                      child: Text(localization.pick_location),
                    ),
                    if (selectedLocation != null)
                      Text(
                        'Selected Location: Lat: ${selectedLocation!.latitude}, Lng: ${selectedLocation!.longitude}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.green),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _validateAndSubmit,
                      child: Text(widget.business == null
                          ? localization.submit
                          : 'Update'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
