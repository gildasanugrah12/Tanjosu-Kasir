class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageEmoji; // emoji placeholder for product image
  final String description;
  final bool isAvailable;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageEmoji,
    this.description = '',
    this.isAvailable = true,
  });
}

final List<Product> dummyProducts = [
  // Matcha Series
  const Product(
    id: 'mc001',
    name: 'Matcha Latte',
    category: 'Matcha',
    price: 38000,
    imageEmoji: '🍵',
    description: 'Premium Japanese matcha with steamed milk',
  ),
  const Product(
    id: 'mc002',
    name: 'Matcha Espresso',
    category: 'Matcha',
    price: 42000,
    imageEmoji: '🍵',
    description: 'Bold espresso shot with ceremonial matcha',
  ),
  const Product(
    id: 'mc003',
    name: 'Iced Matcha',
    category: 'Matcha',
    price: 35000,
    imageEmoji: '🧊',
    description: 'Chilled matcha over ice with oat milk',
  ),
  const Product(
    id: 'mc004',
    name: 'Matcha Affogato',
    category: 'Matcha',
    price: 48000,
    imageEmoji: '🍨',
    description: 'Vanilla gelato drowned in hot matcha',
  ),
  // Coffee
  const Product(
    id: 'cf001',
    name: 'Flat White',
    category: 'Coffee',
    price: 35000,
    imageEmoji: '☕',
    description: 'Ristretto with velvety steamed milk',
  ),
  const Product(
    id: 'cf002',
    name: 'Americano',
    category: 'Coffee',
    price: 28000,
    imageEmoji: '☕',
    description: 'Espresso diluted with hot water',
  ),
  const Product(
    id: 'cf003',
    name: 'Cold Brew',
    category: 'Coffee',
    price: 40000,
    imageEmoji: '🧋',
    description: '18-hour cold-steeped Colombian beans',
  ),
  const Product(
    id: 'cf004',
    name: 'Cappuccino',
    category: 'Coffee',
    price: 34000,
    imageEmoji: '☕',
    description: 'Classic espresso with thick foam',
  ),
  // Food
  const Product(
    id: 'fd001',
    name: 'Matcha Croissant',
    category: 'Food',
    price: 32000,
    imageEmoji: '🥐',
    description: 'Buttery croissant with matcha cream filling',
  ),
  const Product(
    id: 'fd002',
    name: 'Avocado Toast',
    category: 'Food',
    price: 45000,
    imageEmoji: '🥑',
    description: 'Sourdough toast with smashed avo & sesame',
  ),
  const Product(
    id: 'fd003',
    name: 'Granola Bowl',
    category: 'Food',
    price: 52000,
    imageEmoji: '🥣',
    description: 'Handcrafted granola with fresh seasonal fruits',
  ),
  const Product(
    id: 'fd004',
    name: 'Banana Bread',
    category: 'Food',
    price: 25000,
    imageEmoji: '🍌',
    description: 'House-baked banana bread with walnut',
  ),
  // Special
  const Product(
    id: 'sp001',
    name: 'Yuzu Soda',
    category: 'Special',
    price: 38000,
    imageEmoji: '🍋',
    description: 'Sparkling yuzu with honey & fresh mint',
  ),
  const Product(
    id: 'sp002',
    name: 'Rose Latte',
    category: 'Special',
    price: 44000,
    imageEmoji: '🌹',
    description: 'Rose syrup with steamed oat milk',
  ),
  const Product(
    id: 'sp003',
    name: 'Hojicha Latte',
    category: 'Special',
    price: 40000,
    imageEmoji: '🍂',
    description: 'Roasted green tea with creamy milk',
  ),
  const Product(
    id: 'sp004',
    name: 'Signature Set',
    category: 'Special',
    price: 75000,
    imageEmoji: '✨',
    description: 'Matcha latte + matcha croissant combo',
  ),
];

final List<String> productCategories = [
  'All',
  'Matcha',
  'Coffee',
  'Food',
  'Special',
];
