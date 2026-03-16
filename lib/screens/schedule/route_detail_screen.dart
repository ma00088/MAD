import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import '../ticket_booking_screen.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeId;
  final String routeName;
  final String source;
  final String destination;
  final double distance;
  final int duration;

  const RouteDetailScreen({
    Key? key,
    required this.routeId,
    required this.routeName,
    required this.source,
    required this.destination,
    required this.distance,
    required this.duration,
  }) : super(key: key);

  @override
  _RouteDetailScreenState createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  List<Map<String, dynamic>> _stops = [];
  bool _isLoadingStops = false;
  String _selectedDay = 'All';

  final List<String> _daysOfWeek = ['All', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    setState(() {
      _isLoadingStops = true;
    });
    
    try {
      QuerySnapshot stopsSnapshot = await FirebaseFirestore.instance
          .collection('bus_stops')
          .where('routeId', isEqualTo: FirebaseFirestore.instance.doc('routes/${widget.routeId}'))
          .orderBy('stopOrder')
          .get();

      setState(() {
        _stops = stopsSnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['stopName'] ?? 'Unknown Stop',
            'order': data['stopOrder'] ?? 0,
            'time': data['estimatedTimeFromStart'] ?? 0,
          };
        }).toList();
        _isLoadingStops = false;
      });
    } catch (e) {
      setState(() {
        _stops = [];
        _isLoadingStops = false;
      });
    }
  }

  String _formatOperatingDays(List<dynamic>? days) {
    if (days == null || days.isEmpty) return 'No scheduled days';
    
    List<String> daysList = List<String>.from(days);
    
    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    List<String> weekend = ['Sat', 'Sun'];
    
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
      return 'Daily';
    }
    
    return daysList.join(', ');
  }

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
          'Route Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Header
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.routeName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.source} → ${widget.destination}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          Icons.straighten,
                          '${widget.distance} km',
                          'Distance',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          Icons.access_time,
                          '${widget.duration} min',
                          'Duration',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          Icons.route,
                          _isLoadingStops ? 'Loading...' : '${_stops.length} stops',
                          'Total Stops',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Day Filter
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Day',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _daysOfWeek.map((day) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(day),
                            selected: _selectedDay == day,
                            onSelected: (selected) {
                              setState(() {
                                _selectedDay = day;
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: AppColors.primary.withOpacity(0.1),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _selectedDay == day ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: _selectedDay == day ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Schedules Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Available Schedules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 12),

            // Schedules List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text('Error loading schedules'),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No schedules available',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var allSchedules = snapshot.data!.docs;
                
                // Filter schedules manually to match this route
                var routeSchedules = allSchedules.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var routeIdField = data['routeId'];
                  
                  if (routeIdField is DocumentReference) {
                    return routeIdField.path == 'routes/${widget.routeId}';
                  } else if (routeIdField is String) {
                    return routeIdField == widget.routeId || 
                          routeIdField == 'routes/${widget.routeId}';
                  }
                  return false;
                }).toList();

                if (routeSchedules.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No schedules available for this route',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Apply day filter
                var filteredSchedules = routeSchedules.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var operatingDays = List<String>.from(data['operatingDays'] ?? []);
                  
                  if (_selectedDay == 'All') return true;
                  return operatingDays.contains(_selectedDay);
                }).toList();

                if (filteredSchedules.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            _selectedDay == 'All'
                                ? 'No schedules for this route'
                                : 'No schedules on $_selectedDay',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  itemCount: filteredSchedules.length,
                  itemBuilder: (context, index) {
                    var scheduleDoc = filteredSchedules[index];
                    var scheduleData = scheduleDoc.data() as Map<String, dynamic>;
                    List<String> operatingDays = List<String>.from(scheduleData['operatingDays'] ?? []);

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Time Column
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scheduleData['departureTime'] ?? '--:--',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  scheduleData['arrivalTime'] ?? '--:--',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Operating Days
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatOperatingDays(operatingDays),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: operatingDays.map((day) {
                                    bool isSelectedDay = day == _selectedDay && _selectedDay != 'All';
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelectedDay 
                                            ? AppColors.primary 
                                            : AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        day,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isSelectedDay ? Colors.white : AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          // Price and Book button
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'BD ${scheduleData['price'] ?? 25}.00',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TicketBookingScreen(
                                          initialFrom: widget.source,
                                          initialTo: widget.destination,
                                          initialTime: scheduleData['departureTime'],
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(70, 28),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Book',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // Bus Stops Section (only show if there are stops)
            if (_stops.isNotEmpty) ...[
              SizedBox(height: 24),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Bus Stops',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(_stops.length, (index) {
                    var stop = _stops[index];
                    bool isLast = index == _stops.length - 1;
                    
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stop indicator
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: index == 0 ? Colors.green : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 30,
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                              ],
                            ),
                            SizedBox(width: 16),
                            
                            // Stop details
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      stop['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                                        color: index == 0 ? Colors.green : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(stop['time']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isLast) SizedBox(height: 8),
                      ],
                    );
                  }),
                ),
              ),
            ],

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
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

  String _formatTime(int minutesFromStart) {
    if (minutesFromStart == 0) return 'Start';
    int hours = minutesFromStart ~/ 60;
    int minutes = minutesFromStart % 60;
    return '${hours}h ${minutes}m';
  }
}