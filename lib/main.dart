import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/cart_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
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
