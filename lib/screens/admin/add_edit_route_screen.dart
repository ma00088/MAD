import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';

class AddEditRouteScreen extends StatefulWidget {
  final String? routeId;
  final Map<String, dynamic>? routeData;

  const AddEditRouteScreen({Key? key, this.routeId, this.routeData}) : super(key: key);

  @override
  _AddEditRouteScreenState createState() => _AddEditRouteScreenState();
}

class _AddEditRouteScreenState extends State<AddEditRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _routeNameController = TextEditingController();
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;

  // Helper method to safely parse isActive from various formats
  bool _parseIsActive(dynamic value) {
    if (value == null) return true; // Default to true for new routes
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value == 1;
    return true; // Default fallback
  }

  @override
  void initState() {
    super.initState();
    if (widget.routeData != null) {
      // Editing existing route
      _routeNameController.text = widget.routeData!['routeName'] ?? '';
      _sourceController.text = widget.routeData!['source'] ?? '';
      _destinationController.text = widget.routeData!['destination'] ?? '';
      _distanceController.text = (widget.routeData!['distance'] ?? '').toString();
      _durationController.text = (widget.routeData!['duration'] ?? '').toString();
      
      // Safely parse the isActive value
      _isActive = _parseIsActive(widget.routeData!['isActive']);
    }
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _sourceController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> routeData = {
        'routeName': _routeNameController.text.trim(),
        'source': _sourceController.text.trim(),
        'destination': _destinationController.text.trim(),
        'distance': double.parse(_distanceController.text),
        'duration': int.parse(_durationController.text),
        'isActive': _isActive, // This is already a boolean
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.routeId == null) {
        // Add new route
        routeData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('routes').add(routeData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing route
        await FirebaseFirestore.instance
            .collection('routes')
            .doc(widget.routeId)
            .update(routeData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route updated successfully'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          widget.routeId == null ? 'Add New Route' : 'Edit Route',
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
              // Route Name
              Text(
                'Route Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _routeNameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Isa Town → UTB Campus',
                  prefixIcon: Icon(Icons.signpost, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter route name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Source Location
              Text(
                'Source Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _sourceController,
                decoration: InputDecoration(
                  hintText: 'e.g., Isa Town',
                  prefixIcon: Icon(Icons.location_on, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter source location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Destination Location
              Text(
                'Destination Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  hintText: 'e.g., UTB Campus',
                  prefixIcon: Icon(Icons.location_on, color: Colors.red),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter destination location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Distance and Duration Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distance (km)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _distanceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '15.5',
                            prefixIcon: Icon(Icons.straighten, color: Colors.green),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration (min)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '30',
                            prefixIcon: Icon(Icons.access_time, color: Colors.green),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
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
                  onPressed: _isLoading ? null : _saveRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                          widget.routeId == null ? 'Add Route' : 'Update Route',
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
}