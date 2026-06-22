import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'core/theme/app_theme.dart';
import 'providers/cart_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/report_provider.dart'; // ◄ Import provider laporan baru
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: 'https://mjzsuckuxkiskfpkvbbv.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1qenN1Y2t1eGtpc2tmcGt2YmJ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzOTMzMTgsImV4cCI6MjA5NDk2OTMxOH0.7TZ-Ra61NqyHi8T_xYS21DhxjX9oIngdjxf7H9qn7_c',
  );

  runApp(const TanjosuApp());
}

class TanjosuApp extends StatelessWidget {
  const TanjosuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()), // ◄ Provider laporan didaftarkan
      ],
      child: MaterialApp(
        title: 'Tanjosu Cianjur',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(), 
      ),
    );
  }
}