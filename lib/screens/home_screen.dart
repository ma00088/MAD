import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/promo_card.dart';
import '../widgets/bus_tile.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import 'bookings_screen.dart';
import 'ticket_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // Dropdown items for From locations
  final List<String> fromLocations = [
    'Bahrain - Isa Town',
    'Bahrain - Muharraq',
    'Bahrain - Manama',
    'Bahrain - Zalaq',
    'Saudi - Khubar',
  ];
  
  // Dropdown items for To locations  
  final List<String> toLocations = [
    'Bahrain - Salmabad(UTB)',
  ];
  
  String? _selectedFromLocation;
  String? _selectedToLocation;

  @override
  void initState() {
    super.initState();
    // Set default values
    _selectedFromLocation = fromLocations[0]; // Bahrain - Isa Town
    _selectedToLocation = toLocations[0]; // Bahrain - Salmabad(UTB)
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomePage(),
      BookingsScreen(),
      TicketScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Ticket Booking'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // From dropdown field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedFromLocation,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.circle, color: Colors.green, size: 12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: fromLocations.map((location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFromLocation = value;
                      });
                    },
                    hint: Text('From'),
                  ),
                ),
                SizedBox(height: 12),
                // To dropdown field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedToLocation,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.location_on, color: Colors.red, size: 16),
                      suffixIcon: Icon(Icons.swap_vert, color: AppColors.primary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: toLocations.map((location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedToLocation = value;
                      });
                    },
                    hint: Text('To'),
                  ),
                ),
                SizedBox(height: 16),
                // Date selection
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 30)),
                          );
                          if (pickedDate != null) {
                            // Handle date selection
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Date selected: ${pickedDate.day}/${pickedDate.month}/${pickedDate.year}')),
                            );
                          }
                        },
                        icon: Icon(Icons.calendar_today),
                        label: Text('Select Date'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // You can access the selected values here
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Searching buses from $_selectedFromLocation to $_selectedToLocation')),
                          );
                        },
                        child: Text('Search Buses'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Promo Card
          PromoCard(onApply: () {}),

          SizedBox(height: 16),

          // Available Buses
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Available Buses to UTB today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          SizedBox(height: 8),

          Consumer<BookingProvider>(
            builder: (context, provider, child) {
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: provider.availableBuses.length,
                itemBuilder: (context, index) {
                  final bus = provider.availableBuses[index];
                  return BusTile(
                    bus: bus,
                    onTap: () {
                      provider.selectBus(bus);
                      _showBookingDetails(context, provider);
                    },
                  );
                },
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, BookingProvider provider) {
    final bus = provider.selectedBus!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Bus details
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.directions_bus, color: AppColors.primary),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bus.companyName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Bus Type: AC Business Class',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DEPARTURE',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    bus.departureTime,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    bus.fromLocation,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              child: Icon(Icons.arrow_forward, color: Colors.grey),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'ARRIVAL',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    bus.arrivalTime,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Bahrain - Salmabad(UTB)',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildBusFeature(Icons.event_seat, '40 Seats'),
                              _buildBusFeature(Icons.ac_unit, 'AC'),
                              _buildBusFeature(Icons.wifi, 'WiFi'),
                              _buildBusFeature(Icons.tv, 'Entertainment'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Price breakdown
                  Text('Price Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ticket Price (BDT)'),
                      Text('${bus.price}.000 BHD'),
                    ],
                  ),
                  if (provider.discount > 0) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Student Discount', style: TextStyle(color: Colors.green)),
                        Text(
                          '-${provider.discount}.000 BHD',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                  Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (BHD)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${bus.price - provider.discount}.000 BHD',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Promo code
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Student Promo: UTB20 (20% OFF)',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '-${(bus.price * 0.2).toStringAsFixed(3)} BHD',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Proceed button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.applyPromoCode('UTB20');
                        Navigator.pop(context);
                        _showPaymentScreen(context, provider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Proceed to Payment'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBusFeature(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _showPaymentScreen(BuildContext context, BookingProvider provider) {
    final bus = provider.selectedBus!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Payment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              // Payment methods
              _buildPaymentMethod('Credit Card', Icons.credit_card),
              _buildPaymentMethod('Debit Card', Icons.credit_card),
              _buildPaymentMethod('Benefit Pay', Icons.account_balance),
              _buildPaymentMethod('STC Pay', Icons.phone_android),
              Spacer(),
              // Total and pay button
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount (BHD)'),
                        Text(
                          '${bus.price - provider.discount}.000 BHD',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Process payment
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Booking confirmed! Your e-ticket has been sent to your email.')),
                          );
                          Navigator.pop(context);
                          provider.clearSelection();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Pay Now'),
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
  }

  Widget _buildPaymentMethod(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          SizedBox(width: 12),
          Text(title),
          Spacer(),
          Radio(
            value: title, 
            groupValue: 'Credit Card', 
            onChanged: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title selected')),
              );
            },
          ),
        ],
      ),
    );
  }
}