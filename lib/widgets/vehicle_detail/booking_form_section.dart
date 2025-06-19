import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';

class BookingFormSection extends StatefulWidget {
  final Map<String, dynamic> vehicleDetails;

  const BookingFormSection({
    super.key,
    required this.vehicleDetails,
  });

  @override
  State<BookingFormSection> createState() => _BookingFormSectionState();
}

class _BookingFormSectionState extends State<BookingFormSection> {
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime _returnDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _returnTime = const TimeOfDay(hour: 10, minute: 0);
  bool _withDriver = false;

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$formattedDate at $hour:$minute';
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPickup ? _pickupDate : _returnDate,
      firstDate: isPickup ? DateTime.now() : _pickupDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
          // If return date is before new pickup date, update it
          if (_returnDate.isBefore(_pickupDate)) {
            _returnDate = _pickupDate.add(const Duration(days: 1));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isPickup ? _pickupTime : _returnTime,
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupTime = picked;
        } else {
          _returnTime = picked;
        }
      });
    }
  }

  void _applyForBooking() {
    // Here you would navigate to a booking confirmation page or submit the request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking request submitted!')),
    );

    // For debugging - print the booking details
    print('Booking details:');
    print(
        'Vehicle: ${widget.vehicleDetails['make']} ${widget.vehicleDetails['model']}');
    print('Pickup: ${_formatDateTime(_pickupDate, _pickupTime)}');
    print('Return: ${_formatDateTime(_returnDate, _returnTime)}');
    print('With Driver: $_withDriver');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book This Vehicle',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Pickup Date & Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pickup Date & Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                            DateFormat('MMM dd, yyyy').format(_pickupDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                            '${_pickupTime.hour.toString().padLeft(2, '0')}:${_pickupTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Return Date & Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Return Date & Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                            DateFormat('MMM dd, yyyy').format(_returnDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                            '${_returnTime.hour.toString().padLeft(2, '0')}:${_returnTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // With Driver Option
          if (widget.vehicleDetails['pricing']?['daily']?['withDriver'] != null)
            SwitchListTile(
              title: const Text('Include Driver'),
              subtitle: Text(
                  'Add LKR ${widget.vehicleDetails['pricing']['daily']['withDriver']['price'] - widget.vehicleDetails['pricing']['daily']['vehicleOnly']['price']} per day'),
              value: _withDriver,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _withDriver = value;
                });
              },
            ),

          const SizedBox(height: 24),

          // Book Now Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyForBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Book Now'),
            ),
          ),
        ],
      ),
    );
  }
}
