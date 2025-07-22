import 'package:flutter/material.dart';
import '../../../models/vehicle_form_models.dart';
import '../../../utils/form_data_constants.dart';
import '../../../widgets/form_widgets.dart';

class CollectionPointSection extends StatefulWidget {
  final CollectionPoint collectionPoint;
  final Function(CollectionPoint) onCollectionPointChanged;

  const CollectionPointSection({
    super.key,
    required this.collectionPoint,
    required this.onCollectionPointChanged,
  });

  @override
  _CollectionPointSectionState createState() => _CollectionPointSectionState();
}

class _CollectionPointSectionState extends State<CollectionPointSection> {
  late TextEditingController _cityController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.collectionPoint.city);
    _addressController =
        TextEditingController(text: widget.collectionPoint.address);

    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _cityController.addListener(_updateCollectionPoint);
    _addressController.addListener(_updateCollectionPoint);
  }

  void _updateCollectionPoint() {
    final updatedPoint = CollectionPoint(
      district: widget.collectionPoint.district,
      city: _cityController.text,
      address: _addressController.text,
    );

    widget.onCollectionPointChanged(updatedPoint);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormWidgets.buildSectionHeader('Collection Point Address'),
        const SizedBox(height: 16),

        // District dropdown
        FormWidgets.buildDropdown(
          value: widget.collectionPoint.district,
          items: VehicleFormConstants.districtOptions
              .map((district) => DropdownMenuItem<String>(
                    value: district,
                    child: Text(district),
                  ))
              .toList(),
          onChanged: (value) {
            final updatedPoint = CollectionPoint(
              district: value,
              city: _cityController.text,
              address: _addressController.text,
            );
            widget.onCollectionPointChanged(updatedPoint);
          },
          labelText: 'District *',
        ),
        const SizedBox(height: 16),

        // City field
        TextFormField(
          controller: _cityController,
          decoration: InputDecoration(
            labelText: 'City *',
            border: OutlineInputBorder(),
            fillColor: Colors.white,
            filled: true,
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Please enter the city' : null,
        ),
        const SizedBox(height: 16),

        // Address field
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address *',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            fillColor: Colors.white,
            filled: true,
          ),
          maxLines: 3,
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter the collection point address'
              : null,
        ),
      ],
    );
  }
}
