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

  List<File> _pickedImages = []; // List to store multiple images
  List<String> _uploadedImageUrls = []; // List to store uploaded image URLs
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
      _uploadedImageUrls = List<String>.from(widget.business!['images'] ?? []);

      if (widget.business!['location'] != null) {
        final loc = widget.business!['location'];
        selectedLocation = LatLng(loc['latitude'], loc['longitude']);
      }
    }
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _pickedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
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

  void _validateAndSubmit() async {
    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        openingController.text.trim().isEmpty ||
        closingController.text.trim().isEmpty ||
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

    if (_pickedImages.isNotEmpty) {
      await uploadImagesToCloudinary();
    }

    final businessData = {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'phone': phoneController.text.trim(),
      'city': cityController.text.trim(),
      'category': selectedCategory ?? '',
      'images': _uploadedImageUrls, // Store multiple image URLs
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
                    CustomTextField(
                        hintText: localization.business_name,
                        controller: nameController),
                    const SizedBox(height: 10),
                    CustomTextField(
                        hintText: localization.description,
                        controller: descriptionController),
                    const SizedBox(height: 10),
                    CustomTextField(
                        hintText: localization.phone,
                        controller: phoneController),
                    const SizedBox(height: 10),
                    CustomTextField(
                        hintText: localization.city,
                        controller: cityController),
                    const SizedBox(height: 10),
                    // DropdownButtonFormField<String>(
                    //   value: selectedCategory,
                    //   decoration:
                    //       InputDecoration(labelText: localization.catagory),
                    //   items: categories
                    //       .map((category) => DropdownMenuItem(
                    //             value: category,
                    //             child: Text(category),
                    //           ))
                    //       .toList(),
                    //   onChanged: (value) {
                    //     setState(() {
                    //       selectedCategory = value;
                    //     });
                    //   },
                    // ),
                    _buildDropdown(
                      localization
                          .catagory, // label (e.g., "Category" from localization)
                      categories, // list of categories directly
                      (value) {
                        // onChanged function to update the selected value
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
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

  Widget _buildDropdown(
      String label, List<String> items, ValueChanged? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField(
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select a $label' : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
