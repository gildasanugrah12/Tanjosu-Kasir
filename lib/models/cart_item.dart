import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String? note;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.note,
  });

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity, String? note}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }
}
