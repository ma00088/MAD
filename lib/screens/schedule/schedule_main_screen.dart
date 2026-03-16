import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import 'route_detail_screen.dart';

class ScheduleMainScreen extends StatefulWidget {
  @override
  _ScheduleMainScreenState createState() => _ScheduleMainScreenState();
}

class _ScheduleMainScreenState extends State<ScheduleMainScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All Routes';

  final List<String> _filters = ['All Routes', 'Weekdays', 'Weekend', 'Daily'];

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
          'Bus Schedules',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a route...',
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(height: 12),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withOpacity(0.1),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _selectedFilter == filter
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Routes List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('routes')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error loading routes'),
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

                var routes = snapshot.data!.docs;

                return FutureBuilder<Map<String, dynamic>>(
                  future: _getAllRoutesScheduleInfo(routes),
                  builder: (context, allInfoSnapshot) {
                    if (!allInfoSnapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    var routesInfo = allInfoSnapshot.data!;
                    
                    // Filter routes based on selected filter
                    List<DocumentSnapshot> filteredRoutes = [];
                    
                    for (var routeDoc in routes) {
                      String routeId = routeDoc.id;
                      var routeInfo = routesInfo[routeId] ?? {'tripCount': 0, 'scheduleTypes': []};
                      int tripCount = routeInfo['tripCount'];
                      List<String> scheduleTypes = List<String>.from(routeInfo['scheduleTypes']);
                      
                      // Apply search filter
                      bool matchesSearch = true;
                      if (_searchQuery.isNotEmpty) {
                        var data = routeDoc.data() as Map<String, dynamic>;
                        String routeName = data['routeName']?.toString().toLowerCase() ?? '';
                        String source = data['source']?.toString().toLowerCase() ?? '';
                        String destination = data['destination']?.toString().toLowerCase() ?? '';
                        
                        matchesSearch = routeName.contains(_searchQuery) ||
                            source.contains(_searchQuery) ||
                            destination.contains(_searchQuery);
                      }
                      
                      if (!matchesSearch) continue;
                      
                      // Apply type filter
                      bool matchesFilter = true;
                      
                      if (_selectedFilter == 'Weekdays') {
                        matchesFilter = scheduleTypes.contains('weekday');
                      } else if (_selectedFilter == 'Weekend') {
                        matchesFilter = scheduleTypes.contains('weekend');
                      } else if (_selectedFilter == 'Daily') {
                        matchesFilter = scheduleTypes.contains('daily');
                      }
                      
                      if (matchesFilter) {
                        filteredRoutes.add(routeDoc);
                      }
                    }

                    if (filteredRoutes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.route,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No routes found',
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
                      itemCount: filteredRoutes.length,
                      itemBuilder: (context, index) {
                        var routeDoc = filteredRoutes[index];
                        var routeData = routeDoc.data() as Map<String, dynamic>;
                        String routeId = routeDoc.id;
                        var routeInfo = routesInfo[routeId] ?? {'tripCount': 0, 'operatingDaysSummary': 'No schedules'};
                        
                        int tripCount = routeInfo['tripCount'];
                        String operatingDaysSummary = routeInfo['operatingDaysSummary'];
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RouteDetailScreen(
                                  routeId: routeDoc.id,
                                  routeName: routeData['routeName'] ?? 'Unknown Route',
                                  source: routeData['source'] ?? '',
                                  destination: routeData['destination'] ?? '',
                                  distance: (routeData['distance'] ?? 0).toDouble(),
                                  duration: routeData['duration'] ?? 0,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
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
                            child: Row(
                              children: [
                                // Route icon with operating days indicator
                                Stack(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.route,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    ),
                                    if (tripCount > 0)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: Center(
                                            child: Text(
                                              tripCount.toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(width: 16),
                                
                                // Route details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        routeData['routeName'] ?? 'Unknown Route',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${routeData['source']} → ${routeData['destination']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          // Operating days summary
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 12,
                                                  color: Colors.blue,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  operatingDaysSummary,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          
                                          // Duration
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: Colors.orange,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '${routeData['duration'] ?? 0} min',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Arrow
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
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

  Future<Map<String, dynamic>> _getAllRoutesScheduleInfo(List<QueryDocumentSnapshot> routes) async {
    Map<String, dynamic> allInfo = {};
    
    for (var routeDoc in routes) {
      String routeId = routeDoc.id;
      
      try {
        QuerySnapshot schedules = await FirebaseFirestore.instance
            .collection('schedules')
            .where('routeId', isEqualTo: FirebaseFirestore.instance.doc('routes/$routeId'))
            .where('isActive', isEqualTo: true)
            .get();

        int tripCount = schedules.docs.length;
        String operatingDaysSummary = 'No schedules';
        List<String> scheduleTypes = [];
        
        if (tripCount > 0) {
          // Collect all operating days across schedules
          Set<String> allOperatingDays = {};
          bool hasWeekday = false;
          bool hasWeekend = false;
          bool hasDaily = false;
          
          for (var doc in schedules.docs) {
            var data = doc.data() as Map<String, dynamic>;
            List<String> days = List<String>.from(data['operatingDays'] ?? []);
            allOperatingDays.addAll(days);
            
            // Check individual schedule types
            if (days.length == 7) {
              hasDaily = true;
            } else {
              List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
              List<String> weekend = ['Sat', 'Sun'];
              
              if (days.any((day) => weekdays.contains(day))) {
                hasWeekday = true;
              }
              if (days.any((day) => weekend.contains(day))) {
                hasWeekend = true;
              }
            }
          }

          // Add to schedule types
          if (hasWeekday) scheduleTypes.add('weekday');
          if (hasWeekend) scheduleTypes.add('weekend');
          if (hasDaily) scheduleTypes.add('daily');
          
          // Create summary
          List<String> sortedDays = allOperatingDays.toList()..sort();
          
          List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
          List<String> weekend = ['Sat', 'Sun'];
          
          if (sortedDays.length == 5 && 
              sortedDays.every((day) => weekdays.contains(day))) {
            operatingDaysSummary = 'Weekdays';
          } else if (sortedDays.length == 2 && 
                     sortedDays.every((day) => weekend.contains(day))) {
            operatingDaysSummary = 'Weekend';
          } else if (sortedDays.length == 7) {
            operatingDaysSummary = 'Daily';
          } else {
            operatingDaysSummary = sortedDays.join(', ');
          }
        }

        allInfo[routeId] = {
          'tripCount': tripCount,
          'operatingDaysSummary': operatingDaysSummary,
          'scheduleTypes': scheduleTypes,
        };
      } catch (e) {
        print('Error getting schedule info for route $routeId: $e');
        allInfo[routeId] = {
          'tripCount': 0,
          'operatingDaysSummary': 'No schedules',
          'scheduleTypes': [],
        };
      }
    }
    
    return allInfo;
  }
}