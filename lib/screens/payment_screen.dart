void _processPayment() async {
    if (_isLoading) return;

    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    double amountPaid = cart.grandTotal;

    if (_method == 'Tunai') {
      final parsed = double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
      if (parsed == null || parsed < cart.grandTotal) {
        setState(() => _amountError = 'Jumlah bayar kurang dari total');
        return;
      }
      amountPaid = parsed;
    }

    setState(() {
      _isLoading = true;
      _amountError = null;
    });

    try {
      final totalBayar = cart.grandTotal.round();
      final uangDiterima = amountPaid.round();
      final uangKembalian = (uangDiterima - totalBayar);

      // 1. Simpan ke tabel induk transaksi Supabase (SINKRON DENGAN DATABASE BARU)
      final insertedTx = await _supabase.from('transactions').insert({
        'customer_name': widget.customerName.isEmpty ? 'Pelanggan Umum' : widget.customerName,
        'total_price': totalBayar,
        'total_items': cart.totalItems,
        'payment_method': _method,
        'cash_received': _method == 'Tunai' ? uangDiterima : totalBayar, // Jika non-tunai, disamakan dengan total
        'change_amount': _method == 'Tunai' ? uangKembalian : 0,         // Menyesuaikan nama kolom baru di database jirr
        'discount': 0, // Nilai default diskon dimasukkan ke database
      }).select().single();

      final int transactionId = insertedTx['id'];

      // 2. Susun data item belanjaan + Menyisipkan product_id (PENTING UNTUK STOK!)
      final List<Map<String, dynamic>> itemsToInsert = cart.items.map((item) {
        return {
          'transaction_id': transactionId,
          'product_id': item.product.id, // 🚀 SEKARANG PRODUCT ID SUDAH MASUK DB!
          'product_name': item.product.name,
          'price': item.product.price.round(),
          'quantity': item.quantity,
          'subtotal': item.subtotal.round(),
        };
      }).toList();

      // 3. Simpan rincian item ke database cloud Supabase
      await _supabase.from('transaction_items').insert(itemsToInsert);

      // 4. STRATEGI BYPASS TOTAL:
      final List<local_model.TransactionItem> localItemsBebasError = [];

      // Buat objek Transaksi Utama untuk dikirim ke ReceiptWidget
      final local_model.Transaction tx = local_model.Transaction(
        id: transactionId.toString(),
        dateTime: DateTime.parse(insertedTx['created_at']),
        customerName: insertedTx['customer_name'],
        items: localItemsBebasError, 
        subtotal: cart.subtotal,
        taxAmount: cart.taxAmount,
        discountPercent: 0.0,
        discountAmount: 0,    
        grandTotal: cart.grandTotal,
        amountPaid: amountPaid,
        change: uangKembalian.toDouble(),
        paymentMethod: _method,
        orderType: 'Dine In', 
      );

      // Bersihkan keranjang belanja setelah sukses
      try {
        cart.clearCart();
      } catch (_) {}

      setState(() {
        _completedTx = tx;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Gagal menyimpan transaksi: $e')),
      );
    }
  }