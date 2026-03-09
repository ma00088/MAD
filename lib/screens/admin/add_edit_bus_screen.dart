import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';

class AddEditBusScreen extends StatefulWidget {
  final String? busId;
  final Map<String, dynamic>? busData;

  const AddEditBusScreen({Key? key, this.busId, this.busData}) : super(key: key);

  @override
  _AddEditBusScreenState createState() => _AddEditBusScreenState();
}

class _AddEditBusScreenState extends State<AddEditBusScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _busNumberController = TextEditingController();
  final _busNameController = TextEditingController();
  final _totalSeatsController = TextEditingController();
  
  // Dropdown values
  String _selectedBusType = 'Standard';
  bool _isActive = true;
  bool _isLoading = false;
  
  // Amenities
  bool _hasWifi = false;
  bool _hasAC = true;
  bool _hasUSB = false;
  bool _hasToilet = false;
  bool _hasTV = false;

  final List<String> _busTypes = [
    'Standard',
    'AC',
    'Non-AC',
    'Sleeper',
    'AC Sleeper',
    'Luxury',
    'Volvo',
    'Mini',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.busData != null) {
      // Editing existing bus
      _busNumberController.text = widget.busData!['busNumber'] ?? '';
      _busNameController.text = widget.busData!['busName'] ?? '';
      _totalSeatsController.text = (widget.busData!['totalSeats'] ?? '').toString();
      _selectedBusType = widget.busData!['busType'] ?? 'Standard';
      _isActive = widget.busData!['isActive'] ?? true;
      
      // Load amenities if they exist
      if (widget.busData!['amenities'] != null) {
        List<String> amenities = List<String>.from(widget.busData!['amenities']);
        _hasWifi = amenities.contains('wifi');
        _hasAC = amenities.contains('ac');
        _hasUSB = amenities.contains('usb');
        _hasToilet = amenities.contains('toilet');
        _hasTV = amenities.contains('tv');
      }
    }
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _busNameController.dispose();
    _totalSeatsController.dispose();
    super.dispose();
  }

  List<String> _getAmenitiesList() {
    List<String> amenities = [];
    if (_hasWifi) amenities.add('wifi');
    if (_hasAC) amenities.add('ac');
    if (_hasUSB) amenities.add('usb');
    if (_hasToilet) amenities.add('toilet');
    if (_hasTV) amenities.add('tv');
    return amenities;
  }

  Future<void> _saveBus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> busData = {
        'busNumber': _busNumberController.text.trim().toUpperCase(),
        'busName': _busNameController.text.trim(),
        'busType': _selectedBusType,
        'totalSeats': int.parse(_totalSeatsController.text),
        'amenities': _getAmenitiesList(),
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.busId == null) {
        // Add new bus
        busData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('buses').add(busData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update existing bus
        await FirebaseFirestore.instance
            .collection('buses')
            .doc(widget.busId)
            .update(busData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus updated successfully'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.busId == null ? 'Add New Bus' : 'Edit Bus',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bus Number
              Text(
                'Bus Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _busNumberController,
                decoration: InputDecoration(
                  hintText: 'e.g., B-12',
                  prefixIcon: Icon(Icons.directions_bus, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bus number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Bus Name
              Text(
                'Bus Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _busNameController,
                decoration: InputDecoration(
                  hintText: 'e.g., University Express',
                  prefixIcon: Icon(Icons.bus_alert, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bus name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Bus Type
              Text(
                'Bus Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedBusType,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  ),
                  items: _busTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBusType = value!;
                    });
                  },
                ),
              ),
              SizedBox(height: 16),

              // Total Seats
              Text(
                'Total Seats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _totalSeatsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 40',
                  prefixIcon: Icon(Icons.event_seat, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total seats';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Amenities
              Text(
                'Amenities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAmenityChip('WiFi', Icons.wifi, _hasWifi, (val) {
                    setState(() => _hasWifi = val!);
                  }),
                  _buildAmenityChip('AC', Icons.ac_unit, _hasAC, (val) {
                    setState(() => _hasAC = val!);
                  }),
                  _buildAmenityChip('USB Charger', Icons.usb, _hasUSB, (val) {
                    setState(() => _hasUSB = val!);
                  }),
                  _buildAmenityChip('Toilet', Icons.wc, _hasToilet, (val) {
                    setState(() => _hasToilet = val!);
                  }),
                  _buildAmenityChip('TV', Icons.tv, _hasTV, (val) {
                    setState(() => _hasTV = val!);
                  }),
                ],
              ),
              SizedBox(height: 20),

              // Status
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.busId == null ? 'Add Bus' : 'Update Bus',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String label, IconData icon, bool isSelected, Function(bool?) onSelected) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontSize: 12,
      ),
    );
  }
}