import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localbusiness/utils/send_notification.dart';
import 'package:localbusiness/widgets/custom_text_field.dart';
import 'dart:convert';
import 'dart:io';
import 'pick_location_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localbusiness/views/owner/descriptoin_genarator.dart';
import 'package:localbusiness/views/user/location_utils.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
  final TextEditingController customCategoryController =
      TextEditingController();
  final TextEditingController ownernameController = TextEditingController();
  final TextEditingController operatingDaysController = TextEditingController();
  final TextEditingController priceRangeController = TextEditingController();

  String? selectedCategory;
  // Dropdown value
  final List<String> categories = [
    'Restaurant',
    'Hairdresser',
    'Bar',
    'Delivery',
    'Coffee',
    'Shopping',
    'Fitness',
    'Health',
    'Beauty',
    'Entertainment'
  ];

  List<File> _pickedImages = []; // List to store multiple images
  List<String> _uploadedImageUrls = []; // List to store uploaded image URLs
  LatLng? selectedLocation;
  bool _isLoading = false;
  String? userEmail;
  String? _locationName;
  bool _showCustomCategoryField = false; // Toggle custom category input

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
      ownernameController.text = widget.business!['owener_name'] ?? '';
      operatingDaysController.text = widget.business!['operating_days'] ?? '';
      priceRangeController.text = widget.business!['price_range'] ?? '';
      final String businessCategory = widget.business!['category'] ?? '';
      if (categories.contains(businessCategory)) {
        selectedCategory = businessCategory;
      } else {
        _showCustomCategoryField = true;
        customCategoryController.text = businessCategory;
        selectedCategory =
            null; // so the dropdown doesn't have an invalid value
      }
      _uploadedImageUrls = List<String>.from(widget.business!['images'] ?? []);

      if (widget.business!['location'] != null) {
        final loc = widget.business!['location'];
        selectedLocation = LatLng(loc['latitude'], loc['longitude']);
      }
    }
  }

  String getLocalizedCategory(String category, AppLocalizations localization) {
    switch (category) {
      case 'Restaurant':
        return localization.restaurant; // "ምግብ ቤት"
      case 'Hairdresser':
        return localization.hairdresser; // "ፀጉር አስተካካይ"
      case 'Bar':
        return localization.bar; // "መጠጥ ቤት"
      case 'Delivery':
        return localization.delivery; // "ትራንስፖርት"
      case 'Coffee':
        return localization.coffee; // "ቡና ቤት"
      case 'Shopping':
        return localization.shopping;
      case 'Fitness':
        return localization.fitness;
      case 'Health':
        return localization.health;
      case 'Beauty':
        return localization.beauty;
      case 'Entertainment':
        return localization.entertainment;
      default:
        return category;
    }
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    setState(() {
      _pickedImages = pickedFiles.map((file) => File(file.path)).toList();
    });
  }

  Future<void> uploadImagesToCloudinary() async {
    if (_pickedImages.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      for (var image in _pickedImages) {
        final cloudinaryUrl =
            Uri.parse('https://api.cloudinary.com/v1_1/da7hlicdz/image/upload');
        const uploadPreset = 'cloudinary'; // Replace with your preset
        const assetFolder = 'local_business_app';

        final request = http.MultipartRequest('POST', cloudinaryUrl)
          ..fields['upload_preset'] = uploadPreset
          ..fields['folder'] = assetFolder
          ..files.add(await http.MultipartFile.fromPath('file', image.path));

        final response = await request.send();
        final responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(responseData);
          _uploadedImageUrls.add(jsonResponse['secure_url']);
        } else {
          throw Exception('Failed to upload image');
        }
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

      // Fetch the location name
      try {
        _locationName = await LocationUtils.getLocationName(
          selectedLocation!.latitude,
          selectedLocation!.longitude,
        );
      } catch (e) {
        _locationName =
            'Unknown Location'; // Fallback if location name cannot be fetched
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch location name: $e')),
        );
      }

      // Update the UI
      setState(() {
        _locationName =
            _locationName; // Trigger a rebuild to display the location name
      });
    }
  }

  Future<void> saveBusinessToFirestore(
      Map<String, dynamic> businessData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      businessData['creatorId'] = user.uid;
      businessData['creatorEmail'] = user.email;
      // In your BusinessForm or wherever you save data
      businessData['name_lowercase'] = businessData['name'].toLowerCase();

      if (_uploadedImageUrls.isNotEmpty) {
        businessData['images'] = _uploadedImageUrls;
      }
      if (selectedLocation != null) {
        businessData['location'] = {
          'latitude': selectedLocation!.latitude,
          'longitude': selectedLocation!.longitude,
        };
      }

      /// ✅ **Check if editing an existing business**
      if (widget.business != null && widget.business!['id'] != null) {
        // 🔥 **UPDATE the existing business**
        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.business!['id']) // Existing business ID
            .update(businessData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business updated successfully!')),
        );
      } else {
        // ✅ **CREATE a new business**
        DocumentReference businessRef = await FirebaseFirestore.instance
            .collection('businesses')
            .add(businessData);

        await SendNotification.sendNotificationToServer(
            businessData, businessRef.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business added successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save business: $e')),
      );
    }
  }

  Future<void> _generateDescription() async {
    if (nameController.text.isEmpty ||
        selectedCategory == null ||
        cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill in the name, category, and city fields to generate a description.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final description = await AIDescriptionGenerator.generateDescription(
        name: nameController.text.trim(),
        category: selectedCategory!,
        city: cityController.text.trim(),
      );

      setState(() {
        descriptionController.text = description;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate description: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _validateAndSubmit() async {
    // If the user selected "Other (Write your own)", use the custom category
    if (_showCustomCategoryField && customCategoryController.text.isNotEmpty) {
      selectedCategory = customCategoryController.text.trim();
    }

    // Validate all fields
    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        openingController.text.trim().isEmpty ||
        closingController.text.trim().isEmpty ||
        ownernameController.text.trim().isEmpty ||
        priceRangeController.text.trim().isEmpty ||
        operatingDaysController.text.trim().isEmpty ||
        selectedCategory == null ||
        selectedCategory!.isEmpty ||
        (_pickedImages.isEmpty && _uploadedImageUrls.isEmpty) ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill in all fields, select at least one image, and pick a location.'),
        ),
      );
      return;
    }

    // Upload images if any
    if (_pickedImages.isNotEmpty) {
      await uploadImagesToCloudinary();
    }

    // Prepare business data
    final businessData = {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'phone': phoneController.text.trim(),
      'city': cityController.text.trim(),
      'category': selectedCategory ?? '', // Use the selected or custom category
      'images': _uploadedImageUrls, // Store multiple image URLs
      'opening_hours': openingController.text.trim(),
      'closing_hours': closingController.text.trim(),
      'owner_name': ownernameController.text.trim(),
      'operating_days': operatingDaysController.text.trim(),
      'price_range': priceRangeController.text.trim(),
      'created_at': DateTime.now(),
    };

    // Save to Firestore
    await saveBusinessToFirestore(businessData);

    // Call the onSubmit callback if provided
    if (widget.onSubmit != null) {
      widget.onSubmit!(businessData);
    }

    // Navigate back
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
          ? const Center(
              child: SpinKitWave(
              color:
                  Colors.black, // Or use Theme.of(context).colorScheme.primary
              size: 50.0,
            ))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CustomTextField(
                        hintText: localization.business_name,
                        controller: nameController),
                    const SizedBox(height: 10),
                    CustomTextField(
                        hintText: localization.phone,
                        controller: phoneController),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                              hintText: localization.description,
                              controller: descriptionController),
                        ),
                        IconButton(
                          onPressed: _generateDescription,
                          icon: const Icon(Icons.auto_awesome),
                          tooltip: 'Generate Description',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                        hintText: localization.city,
                        controller: cityController),
                    const SizedBox(height: 10),
                    const SizedBox(height: 10),
                    // New field: Business Email
                    CustomTextField(
                      hintText: localization.owners_name,
                      controller: ownernameController,
                    ),
                    const SizedBox(height: 10),
                    // New field: Operating Days
                    CustomTextField(
                      hintText: localization.operating_days,
                      controller: operatingDaysController,
                    ),
                    const SizedBox(height: 10),
                    // New field: Price Range
                    CustomTextField(
                      hintText: localization.prince_range,
                      controller: priceRangeController,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _buildCategoryDropdown(
                        localization.catagory), // Only call once
                    const SizedBox(height: 10),
                    IconButton(
                      onPressed: pickImages,
                      icon: Row(
                        mainAxisSize: MainAxisSize.min, // Keeps the row compact
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            color: Color.fromARGB(255, 192, 128, 255),
                            size: 30,
                          ),
                          const SizedBox(
                              width: 8), // Spacing between icon and text
                          Text(
                            '(${_pickedImages.length + _uploadedImageUrls.length})',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 168, 128, 255),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_pickedImages.isNotEmpty ||
                        _uploadedImageUrls.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              _pickedImages.length + _uploadedImageUrls.length,
                          itemBuilder: (context, index) {
                            if (index < _pickedImages.length) {
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.file(_pickedImages[index],
                                    width: 100, height: 100),
                              );
                            } else {
                              final urlIndex = index - _pickedImages.length;
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.network(
                                    _uploadedImageUrls[urlIndex],
                                    width: 100,
                                    height: 100),
                              );
                            }
                          },
                        ),
                      ),
                    CustomTextField(
                        hintText: localization.opening_hrs,
                        controller: openingController),
                    const SizedBox(height: 20),
                    CustomTextField(
                        hintText: localization.closing_hrs,
                        controller: closingController),
                    const SizedBox(height: 20),
                    if (userEmail != null)
                      Text('Creator Email: $userEmail',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Color.fromARGB(255, 206, 185, 255))),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: pickLocation,
                      child: Text(localization.pick_location),
                    ),
                    if (selectedLocation != null)
                      if (selectedLocation != null)
                        Text(
                          'Selected Location: ${_locationName ?? "Fetching location name..."}',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.green),
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

  Widget _buildCategoryDropdown(String label) {
    final localization = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _showCustomCategoryField ? null : selectedCategory,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: [
            ...categories.map((category) => DropdownMenuItem(
                value: category,
                child: Text(getLocalizedCategory(category, localization)))),
            const DropdownMenuItem(
              value: 'other',
              child: Text('Other (Write your own)'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              if (value == 'other') {
                _showCustomCategoryField = true;
                selectedCategory = null; // Reset selectedCategory
              } else {
                _showCustomCategoryField = false;
                selectedCategory = value;
              }
            });
          },
        ),
        if (_showCustomCategoryField)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CustomTextField(
              hintText: 'Enter your own category',
              controller: customCategoryController,
            ),
          ),
      ],
    );
  }
}
