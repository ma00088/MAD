import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import 'add_edit_schedule_screen.dart';

class ManageSchedulesScreen extends StatefulWidget {
  @override
  _ManageSchedulesScreenState createState() => _ManageSchedulesScreenState();
}

class _ManageSchedulesScreenState extends State<ManageSchedulesScreen> {
  String? _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Schedules',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditScheduleScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.filter_list, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Filter:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      isExpanded: true,
                      underline: SizedBox(),
                      items: [
                        'All',
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ].map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Schedules List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .orderBy('departureTime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error loading schedules'),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No schedules found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first schedule',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter schedules if needed
                var docs = snapshot.data!.docs;
                if (_selectedFilter != 'All') {
                  docs = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    var days = List<String>.from(data['operatingDays'] ?? []);
                    return days.contains(_selectedFilter);
                  }).toList();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var scheduleDoc = docs[index];
                    var scheduleData = scheduleDoc.data() as Map<String, dynamic>;
                    
                    return FutureBuilder(
                      future: _getScheduleDetails(scheduleData),
                      builder: (context, AsyncSnapshot<Map<String, String>> detailsSnapshot) {
                        if (!detailsSnapshot.hasData) {
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        var details = detailsSnapshot.data!;
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.schedule,
                                        color: Colors.orange,
                                        size: 30,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            details['routeName'] ?? 'Unknown Route',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Bus: ${details['busNumber'] ?? 'Unknown'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: scheduleData['isActive'] == true
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        scheduleData['isActive'] == true ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: scheduleData['isActive'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Divider(),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoChip(
                                      Icons.access_time,
                                      '${scheduleData['departureTime']} - ${scheduleData['arrivalTime']}',
                                    ),
                                    _buildInfoChip(
                                      Icons.calendar_today,
                                      _formatDays(scheduleData['operatingDays']),
                                    ),
                                    _buildInfoChip(
                                      Icons.attach_money,
                                      '\$${scheduleData['price'] ?? 25}',
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddEditScheduleScreen(
                                              scheduleId: scheduleDoc.id,
                                              scheduleData: scheduleData,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _showDeleteDialog(
                                        context, 
                                        scheduleDoc.id,
                                        details['routeName'] ?? 'this schedule',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _getScheduleDetails(Map<String, dynamic> scheduleData) async {
    String busNumber = 'Unknown';
    String routeName = 'Unknown';
    
    try {
      // Get bus details
      if (scheduleData['busId'] != null) {
        DocumentReference busRef = scheduleData['busId'] as DocumentReference;
        DocumentSnapshot busDoc = await busRef.get();
        if (busDoc.exists) {
          busNumber = (busDoc.data() as Map<String, dynamic>)['busNumber'] ?? 'Unknown';
        }
      }
      
      // Get route details
      if (scheduleData['routeId'] != null) {
        DocumentReference routeRef = scheduleData['routeId'] as DocumentReference;
        DocumentSnapshot routeDoc = await routeRef.get();
        if (routeDoc.exists) {
          routeName = (routeDoc.data() as Map<String, dynamic>)['routeName'] ?? 'Unknown';
        }
      }
    } catch (e) {
      print('Error getting details: $e');
    }
    
    return {
      'busNumber': busNumber,
      'routeName': routeName,
    };
  }

  String _formatDays(dynamic days) {
    if (days == null) return 'All days';
    if (days is List) {
      List<String> daysList = List<String>.from(days);
      
      // Check for weekdays (Mon-Fri)
      List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
      List<String> weekend = ['Sat', 'Sun'];
      
      // Sort to compare properly
      daysList.sort();
      
      if (daysList.length == 5) {
        List<String> sortedWeekdays = List.from(weekdays)..sort();
        if (daysList.toString() == sortedWeekdays.toString()) {
          return 'Weekdays';
        }
      }
      
      if (daysList.length == 2) {
        List<String> sortedWeekend = List.from(weekend)..sort();
        if (daysList.toString() == sortedWeekend.toString()) {
          return 'Weekend';
        }
      }
      
      if (daysList.length == 7) {
        return 'All Days';
      }
      
      return daysList.join(', ');
    }
    return days.toString();
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String scheduleId, String scheduleName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Schedule',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text('Are you sure you want to delete $scheduleName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                await FirebaseFirestore.instance
                    .collection('schedules')
                    .doc(scheduleId)
                    .delete();
                    
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Schedule deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}