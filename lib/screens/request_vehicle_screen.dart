import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class RequestVehicleScreen extends StatefulWidget {
  const RequestVehicleScreen({super.key});

  @override
  State<RequestVehicleScreen> createState() => _RequestVehicleScreenState();
}

class _RequestVehicleScreenState extends State<RequestVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedVehicleType;
  DateTime? _selectedDateTime;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
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
        'userId': currentUser.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isSubmitting = false);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request Sent'),
          content: const Text(
              'Your inquiry has been submitted successfully! Our team will get back to you shortly.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
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
      backgroundColor: const Color(0xFFF7FBEF),
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
                      hintText: 'Select',
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
                GestureDetector(
                  onTap: _pickDateTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF6F9E7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Select Date&Time',
                        hintStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.calendar_today,
                            color: Color(0xFFB6E23A)),
                      ),
                      controller: TextEditingController(
                        text: _selectedDateTime == null
                            ? ''
                            : DateFormat('yyyy-MM-dd – HH:mm')
                                .format(_selectedDateTime!),
                      ),
                      validator: (value) => _selectedDateTime == null
                          ? 'Please select date & time'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Location Input
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
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
                // Details Text Area
                TextFormField(
                  controller: _detailsController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
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
