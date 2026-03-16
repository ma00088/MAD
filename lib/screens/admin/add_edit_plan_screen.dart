import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';

class AddEditPlanScreen extends StatefulWidget {
  final String? planId;
  final Map<String, dynamic>? planData;

  const AddEditPlanScreen({Key? key, this.planId, this.planData}) : super(key: key);

  @override
  _AddEditPlanScreenState createState() => _AddEditPlanScreenState();
}

class _AddEditPlanScreenState extends State<AddEditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _planNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Features list
  List<String> _features = [];
  final TextEditingController _featureController = TextEditingController();
  
  bool _isPopular = false;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.planData != null) {
      // Editing existing plan
      _planNameController.text = widget.planData!['planName'] ?? '';
      _priceController.text = (widget.planData!['price'] ?? '').toString();
      _durationController.text = (widget.planData!['durationDays'] ?? '').toString();
      _descriptionController.text = widget.planData!['description'] ?? '';
      _isPopular = widget.planData!['isPopular'] ?? false;
      _isActive = widget.planData!['isActive'] ?? true;
      
      // Load features
      if (widget.planData!['features'] != null) {
        if (widget.planData!['features'] is List) {
          _features = List<String>.from(widget.planData!['features']);
        } else if (widget.planData!['features'] is String) {
          _features = (widget.planData!['features'] as String).split(',').map((e) => e.trim()).toList();
        }
      }
    }
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  void _addFeature() {
    if (_featureController.text.trim().isNotEmpty) {
      setState(() {
        _features.add(_featureController.text.trim());
        _featureController.clear();
      });
    }
  }

  void _removeFeature(int index) {
    setState(() {
      _features.removeAt(index);
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> planData = {
        'planName': _planNameController.text.trim(),
        'price': double.parse(_priceController.text),
        'durationDays': int.parse(_durationController.text),
        'description': _descriptionController.text.trim(),
        'features': _features,
        'isPopular': _isPopular,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.planId == null) {
        // Add new plan
        planData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('subscription_plans').add(planData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update existing plan
        await FirebaseFirestore.instance
            .collection('subscription_plans')
            .doc(widget.planId)
            .update(planData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan updated successfully'),
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
          widget.planId == null ? 'Add New Plan' : 'Edit Plan',
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
              // Plan Name
              Text(
                'Plan Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _planNameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Monthly Pass',
                  prefixIcon: Icon(Icons.card_membership, color: Colors.green),
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
                    return 'Please enter plan name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Price and Duration Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price (BD)',
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
                            hintText: '15.00',
                            prefixIcon: Icon(Icons.attach_money, color: Colors.green),
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
                          'Duration (days)',
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
                            prefixIcon: Icon(Icons.calendar_today, color: Colors.green),
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
              SizedBox(height: 16),

              // Description
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe what this plan offers...',
                  prefixIcon: Icon(Icons.description, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Features
              Text(
                'Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              
              // Feature input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _featureController,
                      decoration: InputDecoration(
                        hintText: 'Enter a feature',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.white),
                      onPressed: _addFeature,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Features list
              if (_features.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _features.asMap().entries.map((entry) {
                      int index = entry.key;
                      String feature = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Expanded(child: Text(feature)),
                            IconButton(
                              icon: Icon(Icons.close, size: 16, color: Colors.red),
                              onPressed: () => _removeFeature(index),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No features added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              
              SizedBox(height: 20),

              // Popular and Active switches
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: _isPopular ? Colors.amber : Colors.grey,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mark as Popular',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isPopular,
                            onChanged: (value) {
                              setState(() {
                                _isPopular = value;
                              });
                            },
                            activeColor: Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.power_settings_new,
                      color: _isActive ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active Status',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                        ),
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
                  onPressed: _isLoading ? null : _savePlan,
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
                          widget.planId == null ? 'Add Plan' : 'Update Plan',
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