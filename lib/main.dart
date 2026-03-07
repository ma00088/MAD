import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/booking_provider.dart';
import 'screens/loading_screen.dart';  // Changed from home_screen
import 'utils/theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'UTB Bus Booking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: LoadingScreen(),  // Loading screen is now the first page
      ),
    );
  }
}