import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'welcome_screen.dart';

class RequestVehicleScreen extends StatefulWidget {
  const RequestVehicleScreen({super.key});

  @override
  State<RequestVehicleScreen> createState() => _RequestVehicleScreenState();
}

class _RequestVehicleScreenState extends State<RequestVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedVehicleType;
  DateTime? _selectedDateTime;
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _contactNumber;
  bool _isSubmitting = false;
  final AuthService _authService = AuthService();

  final List<String> _vehicleTypes = [
    'Car',
    'Bike',
    'Three-Wheeler',
  ];

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _dateTimeController.text =
              DateFormat('yyyy-MM-dd – HH:mm').format(_selectedDateTime!);
        });
      }
    }
  }

  Future<void> _ensureLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final didLogin = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (didLogin != true && FirebaseAuth.instance.currentUser == null) {
        // User did not log in, abort submission
        return;
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    // Ensure user is logged in
    await _ensureLoggedIn();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to submit an inquiry.')),
      );
      return;
    }

    // Fetch user details
    final name = currentUser.displayName ?? '';
    final email = currentUser.email ?? '';
    final phone = currentUser.phoneNumber ?? '';

    try {
      await FirebaseFirestore.instance.collection('inquiries').add({
        'vehicleType': _selectedVehicleType,
        'dateTime': _selectedDateTime,
        'location': _locationController.text,
        'details': _detailsController.text,
        'contactNumber': _contactNumber,
        'email': _emailController.text,
        'userId': currentUser.uid,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isSubmitting = false);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFFFF00),
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _dateTimeController.dispose();
    // Reset to default (transparent) when leaving the page
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request a Vehicle',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Vehicle Type Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F9E7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'Select Vehicle Type',
                      hintStyle: TextStyle(color: Colors.black54),
                    ),
                    items: _vehicleTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVehicleType = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a vehicle type' : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Date & Time Picker
                TextFormField(
                  controller: _dateTimeController,
                  readOnly: true,
                  onTap: _pickDateTime,
                  decoration: InputDecoration(
                    labelText: 'Select Date & Time',
                    filled: true,
                    fillColor: const Color(0xFFF6F9E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Tap to select date and time',
                    hintStyle: const TextStyle(color: Colors.black54),
                    prefixIcon: const Icon(Icons.calendar_today,
                        color: Color(0xFFB6E23A)),
                  ),
                  validator: (value) => _selectedDateTime == null
                      ? 'Please select date & time'
                      : null,
                ),
                const SizedBox(height: 16),
                // Location Input
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    filled: true,
                    fillColor: const Color(0xFFF6F9E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter Location',
                    hintStyle: const TextStyle(color: Colors.black54),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a location'
                      : null,
                ),
                const SizedBox(height: 16),
                // Contact Number Input (Mandatory)
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    filled: true,
                    fillColor: const Color(0xFFF6F9E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter Contact Number',
                    hintStyle: const TextStyle(color: Colors.black54),
                  ),
                  initialCountryCode: 'LK', // Sri Lanka by default
                  onChanged: (phone) {
                    _contactNumber = phone.completeNumber;
                  },
                  onSaved: (phone) {
                    _contactNumber = phone?.completeNumber;
                  },
                  validator: (value) {
                    if (value == null || value.number.isEmpty) {
                      return 'Please enter your contact number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email Input (Optional)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (optional)',
                    filled: true,
                    fillColor: const Color(0xFFF6F9E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter Email (optional)',
                    hintStyle: const TextStyle(color: Colors.black54),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailRegExp =
                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+ *');
                      if (!emailRegExp.hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Details Text Area
                TextFormField(
                  controller: _detailsController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Details',
                    filled: true,
                    fillColor: const Color(0xFFF6F9E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter Details',
                    hintStyle: const TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 24),
                // Send Request Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDBFF3B),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text('Send Request'),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Our team will get back to you shortly!',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
