import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import 'route_detail_screen.dart';

class ScheduleTimelineScreen extends StatefulWidget {
  @override
  _ScheduleTimelineScreenState createState() => _ScheduleTimelineScreenState();
}

class _ScheduleTimelineScreenState extends State<ScheduleTimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'All';

  final List<String> _periods = ['All', 'Morning', 'Afternoon', 'Evening'];

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
          'Schedule Timeline',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: AppColors.primary),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date header
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getDayName(_selectedDate.weekday),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Period filters
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _periods.map((period) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(period),
                      selected: _selectedPeriod == period,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primary.withOpacity(0.1),
                      checkmarkColor: AppColors.primary,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Timeline
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .where('isActive', isEqualTo: true)
                  .orderBy('departureTime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading schedules'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var schedules = snapshot.data!.docs;

                // Filter by time period
                if (_selectedPeriod != 'All') {
                  schedules = schedules.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String time = data['departureTime'] ?? '00:00';
                    int hour = int.tryParse(time.split(':')[0]) ?? 0;
                    
                    if (_selectedPeriod == 'Morning') return hour >= 5 && hour < 12;
                    if (_selectedPeriod == 'Afternoon') return hour >= 12 && hour < 17;
                    if (_selectedPeriod == 'Evening') return hour >= 17 || hour < 5;
                    return true;
                  }).toList();
                }

                if (schedules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No schedules found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    var scheduleDoc = schedules[index];
                    var scheduleData = scheduleDoc.data() as Map<String, dynamic>;
                    
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _getRouteAndBusDetails(scheduleData),
                      builder: (context, detailsSnapshot) {
                        if (!detailsSnapshot.hasData) {
                          return SizedBox.shrink();
                        }

                        var details = detailsSnapshot.data!;
                        String time = scheduleData['departureTime'] ?? '00:00';
                        int hour = int.tryParse(time.split(':')[0]) ?? 0;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Time column
                              SizedBox(
                                width: 70,
                                child: Column(
                                  children: [
                                    Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _getTimeColor(hour),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Timeline line
                              SizedBox(
                                width: 30,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 2,
                                      height: 8,
                                      color: Colors.grey[300],
                                    ),
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: _getTimeColor(hour),
                                          width: 2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Schedule card
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RouteDetailScreen(
                                          routeId: details['routeId'],
                                          routeName: details['routeName'],
                                          source: details['source'],
                                          destination: details['destination'],
                                          distance: details['distance'],
                                          duration: details['duration'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          details['routeName'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.directions_bus,
                                              size: 12,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              details['busNumber'] ?? 'Bus',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Spacer(),
                                            Text(
                                              'BD ${scheduleData['price'] ?? 25}.00',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  Future<Map<String, dynamic>> _getRouteAndBusDetails(Map<String, dynamic> scheduleData) async {
    String routeId = '';
    String routeName = 'Unknown Route';
    String source = '';
    String destination = '';
    double distance = 0;
    int duration = 0;
    String busNumber = '';

    try {
      if (scheduleData['routeId'] != null) {
        DocumentReference routeRef = scheduleData['routeId'] as DocumentReference;
        DocumentSnapshot routeDoc = await routeRef.get();
        if (routeDoc.exists) {
          var routeData = routeDoc.data() as Map<String, dynamic>;
          routeId = routeDoc.id;
          routeName = routeData['routeName'] ?? 'Unknown Route';
          source = routeData['source'] ?? '';
          destination = routeData['destination'] ?? '';
          distance = (routeData['distance'] ?? 0).toDouble();
          duration = routeData['duration'] ?? 0;
        }
      }

      if (scheduleData['busId'] != null) {
        DocumentReference busRef = scheduleData['busId'] as DocumentReference;
        DocumentSnapshot busDoc = await busRef.get();
        if (busDoc.exists) {
          var busData = busDoc.data() as Map<String, dynamic>;
          busNumber = busData['busNumber'] ?? '';
        }
      }
    } catch (e) {
      print('Error getting details: $e');
    }

    return {
      'routeId': routeId,
      'routeName': routeName,
      'source': source,
      'destination': destination,
      'distance': distance,
      'duration': duration,
      'busNumber': busNumber,
    };
  }

  Color _getTimeColor(int hour) {
    if (hour < 12) return Colors.orange;
    if (hour < 17) return Colors.blue;
    return Colors.purple;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}