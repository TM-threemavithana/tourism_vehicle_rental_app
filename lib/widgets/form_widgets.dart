import 'package:flutter/material.dart';

class FormWidgets {
  static Widget buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static Widget buildSectionSubheader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static Widget buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    required String labelText,
  }) {
    final isRequired = labelText.endsWith('*');

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          fillColor: Colors.white,
          filled: true,
        ),
        initialValue: value,
        items: items,
        onChanged: onChanged,
        validator: isRequired
            ? (value) =>
                value == null || value.isEmpty ? 'This field is required' : null
            : null,
        isExpanded: true,
        dropdownColor: Colors.white,
        hint: Text('Select ${labelText.replaceAll(' *', '')}'),
      ),
    );
  }

  static Widget buildMileageNote() {
    return const Text(
      'Note: Please put 0 (zero) for both Mileage Limit and Extra Mileage Charge for unlimited limits.',
      style: TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: Colors.grey,
      ),
    );
  }

  static Widget buildPricingField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    required Function validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (isRequired ? ' *' : ''),
        border: const OutlineInputBorder(),
        prefixText: 'Rs. ',
        fillColor: Colors.white,
        filled: true,
      ),
      keyboardType: TextInputType.number,
      validator: (value) => validator(value),
    );
  }

  static Widget buildMileageField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    required Function validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (isRequired ? ' *' : ''),
        border: const OutlineInputBorder(),
        hintText: 'Enter 0 for unlimited',
        fillColor: Colors.white,
        filled: true,
      ),
      keyboardType: TextInputType.number,
      validator: (value) => validator(value),
    );
  }

  static Widget buildNoteContainer(String text, {Color color = Colors.blue}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ),
    );
  }
}

class SizedSize extends StatelessWidget {
  final double width;
  final double height;

  const SizedSize({super.key, this.width = 0, this.height = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height);
  }
}
