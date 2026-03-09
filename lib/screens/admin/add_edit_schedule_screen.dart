import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final String? scheduleId;
  final Map<String, dynamic>? scheduleData;

  const AddEditScheduleScreen({Key? key, this.scheduleId, this.scheduleData}) : super(key: key);

  @override
  _AddEditScheduleScreenState createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _departureTimeController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _priceController = TextEditingController();
  
  // Dropdown values
  String? _selectedBusId;
  String? _selectedRouteId;
  bool _isActive = true;
  bool _isLoading = false;
  
  // Operating days
  Map<String, bool> _operatingDays = {
    'Mon': true,
    'Tue': true,
    'Wed': true,
    'Thu': true,
    'Fri': true,
    'Sat': false,
    'Sun': false,
  };

  // Data lists
  List<QueryDocumentSnapshot> _buses = [];
  List<QueryDocumentSnapshot> _routes = [];
  bool _isLoadingData = true;

  // Helper method to safely parse isActive from various formats
  bool _parseIsActive(dynamic value) {
    if (value == null) return true; // Default to true for new schedules
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value == 1;
    return true; // Default fallback
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load active buses
      QuerySnapshot busesSnapshot = await FirebaseFirestore.instance
          .collection('buses')
          .get();
      
      // Load all routes first, then filter manually to handle isActive correctly
      QuerySnapshot routesSnapshot = await FirebaseFirestore.instance
          .collection('routes')
          .get();
      
      // Filter routes manually to handle different isActive formats
      List<QueryDocumentSnapshot> activeRoutes = routesSnapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        var isActive = data['isActive'];
        
        // Handle different types of isActive values
        if (isActive == null) return false;
        if (isActive is bool) return isActive;
        if (isActive is String) return isActive.toLowerCase() == 'true';
        if (isActive is num) return isActive == 1;
        return false;
      }).toList();
      
      // Set selected values if editing - do this BEFORE setting state
      if (widget.scheduleData != null) {
        if (widget.scheduleData!['busId'] != null) {
          DocumentReference busRef = widget.scheduleData!['busId'] as DocumentReference;
          _selectedBusId = busRef.id;
        }
        if (widget.scheduleData!['routeId'] != null) {
          DocumentReference routeRef = widget.scheduleData!['routeId'] as DocumentReference;
          _selectedRouteId = routeRef.id;
        }
        
        // Set other fields
        _departureTimeController.text = widget.scheduleData!['departureTime'] ?? '';
        _arrivalTimeController.text = widget.scheduleData!['arrivalTime'] ?? '';
        _priceController.text = (widget.scheduleData!['price'] ?? '25').toString();
        _isActive = _parseIsActive(widget.scheduleData!['isActive']);
        
        // Load operating days
        if (widget.scheduleData!['operatingDays'] != null) {
          List<String> days = List<String>.from(widget.scheduleData!['operatingDays']);
          _operatingDays = {
            'Mon': days.contains('Mon'),
            'Tue': days.contains('Tue'),
            'Wed': days.contains('Wed'),
            'Thu': days.contains('Thu'),
            'Fri': days.contains('Fri'),
            'Sat': days.contains('Sat'),
            'Sun': days.contains('Sun'),
          };
        }
      }

      setState(() {
        _buses = busesSnapshot.docs;
        _routes = activeRoutes; // Use filtered active routes
        _isLoadingData = false;
      });

    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoadingData = false);
      }
    }
  }

  List<String> _getSelectedDays() {
    List<String> selected = [];
    _operatingDays.forEach((day, isSelected) {
      if (isSelected) selected.add(day);
    });
    return selected;
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedBusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a bus'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a route'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> scheduleData = {
        'busId': FirebaseFirestore.instance.collection('buses').doc(_selectedBusId),
        'routeId': FirebaseFirestore.instance.collection('routes').doc(_selectedRouteId),
        'departureTime': _departureTimeController.text.trim(),
        'arrivalTime': _arrivalTimeController.text.trim(),
        'operatingDays': _getSelectedDays(),
        'price': double.parse(_priceController.text),
        'isActive': _isActive, // This is already a boolean
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.scheduleId == null) {
        // Add new schedule
        scheduleData['createdAt'] = FieldValue.serverTimestamp();
        scheduleData['availableSeats'] = 40; // Default seats available
        
        await FirebaseFirestore.instance.collection('schedules').add(scheduleData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Schedule added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing schedule
        await FirebaseFirestore.instance
            .collection('schedules')
            .doc(widget.scheduleId)
            .update(scheduleData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Schedule updated successfully'),
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
          widget.scheduleId == null ? 'Add New Schedule' : 'Edit Schedule',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingData
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading data...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _routes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: Colors.orange,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Active Routes Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please add and activate routes first',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Select Bus
                        Text(
                          'Select Bus',
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
                            value: _selectedBusId,
                            hint: Text('Choose a bus'),
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            items: _buses.map((busDoc) {
                              var busData = busDoc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: busDoc.id,
                                child: Text(
                                  '${busData['busNumber']} - ${busData['busName']}',
                                  style: TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBusId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a bus';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 16),

                        // Select Route
                        Text(
                          'Select Route',
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
                            value: _selectedRouteId,
                            hint: Text('Choose a route'),
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            items: _routes.map((routeDoc) {
                              var routeData = routeDoc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: routeDoc.id,
                                child: Text(
                                  routeData['routeName'] ?? 'Unknown Route',
                                  style: TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRouteId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a route';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 16),

                        // Departure Time
                        Text(
                          'Departure Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _departureTimeController,
                          decoration: InputDecoration(
                            hintText: 'e.g., 07:30 AM',
                            prefixIcon: Icon(Icons.access_time, color: Colors.orange),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter departure time';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Arrival Time
                        Text(
                          'Arrival Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _arrivalTimeController,
                          decoration: InputDecoration(
                            hintText: 'e.g., 08:00 AM',
                            prefixIcon: Icon(Icons.access_time, color: Colors.orange),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter arrival time';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Price
                        Text(
                          'Price (\$)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'e.g., 25',
                            prefixIcon: Icon(Icons.attach_money, color: Colors.orange),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // Operating Days
                        Text(
                          'Operating Days',
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
                            _buildDayChip('Mon', Icons.calendar_today),
                            _buildDayChip('Tue', Icons.calendar_today),
                            _buildDayChip('Wed', Icons.calendar_today),
                            _buildDayChip('Thu', Icons.calendar_today),
                            _buildDayChip('Fri', Icons.calendar_today),
                            _buildDayChip('Sat', Icons.calendar_today),
                            _buildDayChip('Sun', Icons.calendar_today),
                          ],
                        ),
                        
                        // Quick select buttons
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _operatingDays = {
                                      'Mon': true,
                                      'Tue': true,
                                      'Wed': true,
                                      'Thu': true,
                                      'Fri': true,
                                      'Sat': false,
                                      'Sun': false,
                                    };
                                  });
                                },
                                child: Text('Weekdays'),
                              ),
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _operatingDays = {
                                      'Mon': false,
                                      'Tue': false,
                                      'Wed': false,
                                      'Thu': false,
                                      'Fri': false,
                                      'Sat': true,
                                      'Sun': true,
                                    };
                                  });
                                },
                                child: Text('Weekend'),
                              ),
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _operatingDays = {
                                      'Mon': true,
                                      'Tue': true,
                                      'Wed': true,
                                      'Thu': true,
                                      'Fri': true,
                                      'Sat': true,
                                      'Sun': true,
                                    };
                                  });
                                },
                                child: Text('All Days'),
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
                            onPressed: _isLoading ? null : _saveSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
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
                                    widget.scheduleId == null ? 'Add Schedule' : 'Update Schedule',
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

  Widget _buildDayChip(String day, IconData icon) {
    return FilterChip(
      label: Text(day),
      avatar: Icon(icon, size: 14),
      selected: _operatingDays[day] ?? false,
      onSelected: (selected) {
        setState(() {
          _operatingDays[day] = selected;
        });
      },
      selectedColor: Colors.orange.withOpacity(0.2),
      checkmarkColor: Colors.orange,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: _operatingDays[day] ?? false ? Colors.orange : AppColors.textPrimary,
        fontSize: 12,
      ),
    );
  }
}