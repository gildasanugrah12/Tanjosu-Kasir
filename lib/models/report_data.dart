enum ReportPeriod { harian, mingguan, bulanan, tahunan }

class SalesDatum {
  final String label;
  final double amount;
  final int transactions;

  const SalesDatum({
    required this.label,
    required this.amount,
    required this.transactions,
  });
}

class ReportSummary {
  final double totalRevenue;
  final int totalTransactions;
  final int totalItems;
  final double avgOrder;
  final double revenueChange; // % vs periode sebelumnya
  final double transactionChange;

  const ReportSummary({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalItems,
    required this.avgOrder,
    required this.revenueChange,
    required this.transactionChange,
  });
}

class TopProduct {
  final String name;
  final String emoji;
  final int qty;
  final double pct;

  const TopProduct({
    required this.name,
    required this.emoji,
    required this.qty,
    required this.pct,
  });
}

// ── Dummy chart data ──────────────────────────────────────────────

const harianData = [
  SalesDatum(label: '08:00', amount: 45000, transactions: 1),
  SalesDatum(label: '09:00', amount: 115000, transactions: 3),
  SalesDatum(label: '10:00', amount: 178000, transactions: 5),
  SalesDatum(label: '11:00', amount: 220000, transactions: 6),
  SalesDatum(label: '12:00', amount: 312000, transactions: 9),
  SalesDatum(label: '13:00', amount: 267000, transactions: 7),
  SalesDatum(label: '14:00', amount: 198000, transactions: 5),
  SalesDatum(label: '15:00', amount: 145000, transactions: 4),
  SalesDatum(label: '16:00', amount: 234000, transactions: 6),
  SalesDatum(label: '17:00', amount: 289000, transactions: 8),
  SalesDatum(label: '18:00', amount: 356000, transactions: 10),
  SalesDatum(label: '19:00', amount: 410000, transactions: 11),
  SalesDatum(label: '20:00', amount: 298000, transactions: 8),
  SalesDatum(label: '21:00', amount: 167000, transactions: 4),
];

const mingguanData = [
  SalesDatum(label: 'Sen', amount: 720000, transactions: 28),
  SalesDatum(label: 'Sel', amount: 610000, transactions: 22),
  SalesDatum(label: 'Rab', amount: 834000, transactions: 31),
  SalesDatum(label: 'Kam', amount: 920000, transactions: 35),
  SalesDatum(label: 'Jum', amount: 1100000, transactions: 42),
  SalesDatum(label: 'Sab', amount: 1380000, transactions: 52),
  SalesDatum(label: 'Min', amount: 1250000, transactions: 48),
];

const bulananData = [
  SalesDatum(label: 'Mg 1', amount: 4200000, transactions: 158),
  SalesDatum(label: 'Mg 2', amount: 5100000, transactions: 192),
  SalesDatum(label: 'Mg 3', amount: 4750000, transactions: 178),
  SalesDatum(label: 'Mg 4', amount: 6300000, transactions: 237),
];

const tahunanData = [
  SalesDatum(label: 'Jan', amount: 18500000, transactions: 680),
  SalesDatum(label: 'Feb', amount: 16200000, transactions: 598),
  SalesDatum(label: 'Mar', amount: 19800000, transactions: 735),
  SalesDatum(label: 'Apr', amount: 21300000, transactions: 792),
  SalesDatum(label: 'Mei', amount: 23600000, transactions: 865),
  SalesDatum(label: 'Jun', amount: 22100000, transactions: 818),
  SalesDatum(label: 'Jul', amount: 24500000, transactions: 901),
  SalesDatum(label: 'Agu', amount: 26800000, transactions: 978),
  SalesDatum(label: 'Sep', amount: 25200000, transactions: 924),
  SalesDatum(label: 'Okt', amount: 27900000, transactions: 1023),
  SalesDatum(label: 'Nov', amount: 29300000, transactions: 1072),
  SalesDatum(label: 'Des', amount: 34100000, transactions: 1248),
];

// ── Summary per periode ───────────────────────────────────────────

const harianSummary = ReportSummary(
  totalRevenue: 3234000,
  totalTransactions: 87,
  totalItems: 234,
  avgOrder: 37172,
  revenueChange: 12.4,
  transactionChange: 8.2,
);

const mingguanSummary = ReportSummary(
  totalRevenue: 6814000,
  totalTransactions: 258,
  totalItems: 712,
  avgOrder: 26411,
  revenueChange: 9.7,
  transactionChange: 5.3,
);

const bulananSummary = ReportSummary(
  totalRevenue: 20350000,
  totalTransactions: 765,
  totalItems: 2184,
  avgOrder: 26601,
  revenueChange: 15.2,
  transactionChange: 11.8,
);

const tahunanSummary = ReportSummary(
  totalRevenue: 289300000,
  totalTransactions: 10634,
  totalItems: 30421,
  avgOrder: 27207,
  revenueChange: 23.5,
  transactionChange: 18.9,
);

// ── Top products ──────────────────────────────────────────────────

const topProductsHarian = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 34, pct: 0.85),
  TopProduct(name: 'KHS Coklat Crunchy', emoji: '🧇', qty: 28, pct: 0.70),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 22, pct: 0.55),
  TopProduct(name: 'KHS Milo Coco Krunch', emoji: '🥣', qty: 18, pct: 0.45),
  TopProduct(name: 'KHS Strawberry', emoji: '🍓', qty: 14, pct: 0.35),
];

const topProductsMingguan = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 198, pct: 0.90),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 162, pct: 0.74),
  TopProduct(name: 'KHS Alpukat', emoji: '🥑', qty: 145, pct: 0.66),
  TopProduct(name: 'KHS Coklat Regal', emoji: '🍪', qty: 112, pct: 0.51),
  TopProduct(name: 'KHS Milo', emoji: '🥤', qty: 98, pct: 0.45),
];

const topProductsBulanan = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 745, pct: 0.92),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 612, pct: 0.75),
  TopProduct(name: 'KHS Strawberry Ice Cream', emoji: '🍨', qty: 534, pct: 0.66),
  TopProduct(name: 'KHS Alpukat', emoji: '🥑', qty: 421, pct: 0.52),
  TopProduct(name: 'KHS Durian Keju', emoji: '🧀', qty: 387, pct: 0.47),
];

const topProductsTahunan = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 8924, pct: 0.95),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 7312, pct: 0.78),
  TopProduct(name: 'KHS Alpukat', emoji: '🥑', qty: 6543, pct: 0.70),
  TopProduct(name: 'KHS Milo Coco Krunch', emoji: '🥣', qty: 5128, pct: 0.55),
  TopProduct(name: 'KHS Tiramisu Regal', emoji: '🍪', qty: 4891, pct: 0.52),
];

// ── Helper to get data by period ──────────────────────────────────

List<SalesDatum> getSalesData(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.harian: return harianData;
    case ReportPeriod.mingguan: return mingguanData;
    case ReportPeriod.bulanan: return bulananData;
    case ReportPeriod.tahunan: return tahunanData;
  }
}

ReportSummary getSummary(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.harian: return harianSummary;
    case ReportPeriod.mingguan: return mingguanSummary;
    case ReportPeriod.bulanan: return bulananSummary;
    case ReportPeriod.tahunan: return tahunanSummary;
  }
}

List<TopProduct> getTopProducts(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.harian: return topProductsHarian;
    case ReportPeriod.mingguan: return topProductsMingguan;
    case ReportPeriod.bulanan: return topProductsBulanan;
    case ReportPeriod.tahunan: return topProductsTahunan;
  }
}

String getPeriodLabel(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.harian: return 'Hari Ini';
    case ReportPeriod.mingguan: return '7 Hari Terakhir';
    case ReportPeriod.bulanan: return 'Bulan Ini';
    case ReportPeriod.tahunan: return 'Tahun Ini';
  }
}
