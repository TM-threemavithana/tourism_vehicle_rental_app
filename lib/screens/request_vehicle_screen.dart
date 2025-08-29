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
import '../utils/responsive_helper.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your inquiry has been submitted successfully!'),
          duration: Duration(seconds: 1),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
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
        title: Text(
          'Request a Vehicle',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                mobile: 18, tablet: 20, desktop: 22),
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 8, tablet: 12, desktop: 16)),
                // Vehicle Type Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F9E7),
                    borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context,
                            mobile: 8, tablet: 12, desktop: 16)),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.getResponsiveSpacing(
                              context,
                              mobile: 16,
                              tablet: 20,
                              desktop: 24),
                          vertical: ResponsiveHelper.getResponsiveSpacing(
                              context,
                              mobile: 14,
                              tablet: 18,
                              desktop: 22)),
                      hintText: 'Select Vehicle Type',
                      hintStyle: TextStyle(
                        color: Colors.black54,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18),
                      ),
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
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 16, tablet: 20, desktop: 24)),
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
                      borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context,
                              mobile: 8, tablet: 12, desktop: 16)),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Tap to select date and time',
                    hintStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 14, tablet: 16, desktop: 18),
                    ),
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: const Color(0xFFB6E23A),
                      size: ResponsiveHelper.getResponsiveIconSize(context),
                    ),
                  ),
                  validator: (value) => _selectedDateTime == null
                      ? 'Please select date & time'
                      : null,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 16, tablet: 20, desktop: 24)),
                // Location Input
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    filled: true,
                    fillColor: const Color(0xFFF6F9E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context,
                              mobile: 8, tablet: 12, desktop: 16)),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter Location',
                    hintStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 14, tablet: 16, desktop: 18),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a location'
                      : null,
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 16, tablet: 20, desktop: 24)),
                // Contact Number Input (Mandatory)
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    filled: true,
                    fillColor: const Color(0xFFF6F9E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context,
                              mobile: 8, tablet: 12, desktop: 16)),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter Contact Number',
                    hintStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 14, tablet: 16, desktop: 18),
                    ),
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
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 16, tablet: 20, desktop: 24)),
                // Email Input (Optional)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (optional)',
                    filled: true,
                    fillColor: const Color(0xFFF6F9E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context,
                              mobile: 8, tablet: 12, desktop: 16)),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter Email (optional)',
                    hintStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 14, tablet: 16, desktop: 18),
                    ),
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
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 16, tablet: 20, desktop: 24)),
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
                      borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context,
                              mobile: 8, tablet: 12, desktop: 16)),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter Details',
                    hintStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                          mobile: 14, tablet: 16, desktop: 18),
                    ),
                  ),
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 24, tablet: 32, desktop: 40)),
                // Send Request Button
                SizedBox(
                  height: ResponsiveHelper.isTablet(context) ? 56 : 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDBFF3B),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context,
                                mobile: 8, tablet: 12, desktop: 16)),
                      ),
                      textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20)),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? SizedBox(
                            width: ResponsiveHelper.getResponsiveIconSize(
                                context,
                                mobile: 24,
                                tablet: 28,
                                desktop: 32),
                            height: ResponsiveHelper.getResponsiveIconSize(
                                context,
                                mobile: 24,
                                tablet: 28,
                                desktop: 32),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text('Send Request'),
                  ),
                ),
                SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context,
                        mobile: 12, tablet: 16, desktop: 20)),
                Center(
                  child: Text(
                    'Our team will get back to you shortly!',
                    style: TextStyle(
                        color: Colors.black54,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 16)),
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
