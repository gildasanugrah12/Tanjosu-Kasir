import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  StreamSubscription? _reportSubscription;

  double _totalRevenue = 0.0;
  int _totalOrders = 0;
  int _totalItemsSold = 0;
  bool _isLoading = false;

  double get totalRevenue => _totalRevenue;
  int get totalOrders => _totalOrders;
  int get totalItemsSold => _totalItemsSold;
  bool get isLoading => _isLoading;

  ReportProvider() {
    fetchTodayReport();
    listenToTodayReport();
  }

  Future<void> fetchTodayReport() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 1. Ambil transaksi hari ini
      final txResponse = await _supabase
          .from('transactions')
          .select('id, total_price')
          .gte('created_at', '$todayStr 00:00:00');

      if (txResponse == null || (txResponse as List).isEmpty) {
        _resetData();
        return;
      }

      final List<dynamic> txList = txResponse as List<dynamic>;
      final List<int> todayDbIds = txList.map((tx) => (tx['id'] as num).toInt()).toList();

      int tempOrders = txList.length;
      double tempRevenue = 0.0;
      for (var tx in txList) {
        tempRevenue += (tx['total_price'] as num? ?? 0).toDouble();
      }

      // 2. Ambil items (Menggunakan filter 'in' yang pasti jalan di semua versi)
      final itemsResponse = await _supabase
          .from('transaction_items')
          .select('quantity')
          .filter('transaction_id', 'in', todayDbIds);

      int tempPcs = 0;
      if (itemsResponse != null && (itemsResponse as List).isNotEmpty) {
        for (var item in itemsResponse as List<dynamic>) {
          tempPcs += (item['quantity'] as num? ?? 0).toInt();
        }
      }

      _totalOrders = tempOrders;
      _totalRevenue = tempRevenue;
      _totalItemsSold = tempPcs;
      
      debugPrint('✅ Data Report Terupdate: $_totalOrders Transaksi, Rp$_totalRevenue, $_totalItemsSold Pcs');

    } catch (e) {
      debugPrint('❌ Error: $e');
      _resetData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenToTodayReport() {
    _reportSubscription?.cancel();
    _reportSubscription = _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .listen((_) => fetchTodayReport());
  }

  void _resetData() {
    _totalRevenue = 0.0;
    _totalOrders = 0;
    _totalItemsSold = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _reportSubscription?.cancel();
    super.dispose();
  }
}